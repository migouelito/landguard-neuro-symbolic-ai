"""LandGuard orchestration pipeline.

Loads the synthetic dataset, prepares Prolog facts, optionally invokes local
logic tools when they are installed, and exports the consolidated XAI report.
"""

from __future__ import annotations

import json
import shutil
import subprocess
from datetime import datetime
from pathlib import Path

import pandas as pd


ROOT_DIR = Path(__file__).resolve().parent
DATA_FILE = ROOT_DIR / "data" / "dataset.csv"
PROLOG_DIR = ROOT_DIR / "prolog"
DEEPPROBLOG_DIR = ROOT_DIR / "deepproblog"
REPORT_FILE = ROOT_DIR / "rapport_final.json"
DATASET_FACTS = PROLOG_DIR / "dataset_facts.pl"
PROBLOG_BIN = ROOT_DIR / ".venv" / "bin" / "problog"

EXPECTED_COLUMNS = [
    "id",
    "nom",
    "type",
    "nb_parcelles",
    "parcelles_urbaines",
    "parcelles_rurales",
    "frequence_revente",
    "plus_value",
    "nb_liens_reseau",
    "partage_telephone",
    "partage_adresse",
    "age_premier_achat",
    "nb_dossiers_traites",
    "agent_public",
    "description",
    "score_risque",
]


def load_dataset() -> pd.DataFrame:
    if not DATA_FILE.exists():
        raise FileNotFoundError(f"Dataset introuvable: {DATA_FILE}")

    df = pd.read_csv(DATA_FILE)
    missing = [column for column in EXPECTED_COLUMNS if column not in df.columns]
    if missing:
        raise ValueError(f"Colonnes manquantes dans {DATA_FILE}: {missing}")

    df = df[EXPECTED_COLUMNS].copy()
    df = df.sort_values("id").reset_index(drop=True)
    print(f"Dataset chargé: {len(df)} cas")
    print(df["type"].value_counts().to_string())
    return df


def write_dataset_facts(df: pd.DataFrame) -> None:
    PROLOG_DIR.mkdir(exist_ok=True)
    lines = ["% Faits générés par main.py", ""]
    for _, row in df.iterrows():
        name = str(row["nom"]).replace("'", "_")
        lines.append(
            f"cas_analyse('{name}', {int(row['nb_parcelles'])}, {float(row['score_risque']):.2f})."
        )
    DATASET_FACTS.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Faits Prolog générés: {DATASET_FACTS}")


def run_optional_command(label: str, command: list[str], timeout: int = 45) -> str:
    executable = command[0]
    if shutil.which(executable) is None:
        message = f"{label}: ignoré, {executable} absent du PATH."
        print(message)
        return message

    try:
        result = subprocess.run(
            command,
            cwd=ROOT_DIR,
            capture_output=True,
            text=True,
            timeout=timeout,
            check=False,
        )
    except subprocess.TimeoutExpired:
        message = f"{label}: timeout après {timeout}s."
        print(message)
        return message

    output = (result.stdout or "") + ("\n" + result.stderr if result.stderr else "")
    summary = output.strip() or f"{label}: terminé sans sortie."
    print(summary)
    return summary


def run_symbolic_pipeline() -> str:
    return run_optional_command(
        "Moteur Prolog",
        [
            "swipl",
            "-q",
            "-g",
            "['prolog/dataset_facts.pl','prolog/inference_engine.pl'], lancer_detection, halt.",
        ],
    )


def run_probabilistic_pipeline() -> str:
    problog_command = str(PROBLOG_BIN) if PROBLOG_BIN.exists() else "problog"
    return run_optional_command(
        "ProbLog",
        [problog_command, str(PROLOG_DIR / "queries.pl")],
    )


def run_neurosymbolic_pipeline() -> str:
    if not (DEEPPROBLOG_DIR / "model_weights.pth").exists():
        return "DeepProbLog: poids du modèle absents, entraînement non relancé automatiquement."
    return run_optional_command(
        "Démo neuro-symbolique",
        ["swipl", "-q", "-g", "['deepproblog/deepproblog_model.pl'], main, halt."],
    )


def case_explanation(row: pd.Series) -> str:
    clues: list[str] = []
    if row["nb_parcelles"] >= 4:
        clues.append(f"Possède {int(row['nb_parcelles'])} parcelles")
    if row["frequence_revente"] >= 2:
        clues.append(f"Fréquence de revente élevée: {int(row['frequence_revente'])}")
    if row["plus_value"] > 0.5:
        clues.append(f"Plus-value anormale: {row['plus_value'] * 100:.0f}%")
    if row["nb_liens_reseau"] >= 2:
        clues.append(f"Réseau suspect: {int(row['nb_liens_reseau'])} liens")
    if row["partage_telephone"] == 1:
        clues.append("Partage de téléphone suspect")
    if row["partage_adresse"] == 1:
        clues.append("Partage d'adresse suspect")
    if row["agent_public"] == 1:
        clues.append("Agent public impliqué")
    return " | ".join(clues) if clues else "Aucun signal fort détecté"


def risk_level(score: float) -> str:
    if score >= 0.80:
        return "CRITIQUE"
    if score >= 0.60:
        return "ÉLEVÉ"
    if score >= 0.30:
        return "MOYEN"
    return "FAIBLE"


def generate_report(
    df: pd.DataFrame,
    prolog_output: str,
    problog_output: str,
    deepproblog_output: str,
) -> dict:
    report = {
        "meta": {
            "date": datetime.now().isoformat(),
            "version": "1.0",
            "systeme": "LandGuard Neuro-Symbolic AI",
        },
        "dataset": {
            "total_cas": int(len(df)),
            "repartition": {str(k): int(v) for k, v in df["type"].value_counts().items()},
            "statistiques": {
                "score_risque_moyen": float(df["score_risque"].mean()),
                "score_risque_max": float(df["score_risque"].max()),
                "score_risque_min": float(df["score_risque"].min()),
            },
        },
        "resume": {},
        "alertes": [],
        "detections": [],
        "execution": {
            "prolog": prolog_output,
            "problog": problog_output,
            "deepproblog": deepproblog_output,
        },
    }

    for case_type, subset in df.groupby("type"):
        report["resume"][case_type] = {
            "nb_cas": int(len(subset)),
            "score_moyen": float(subset["score_risque"].mean()),
            "alerte": bool(subset["score_risque"].mean() >= 0.60),
        }

    for _, row in df.iterrows():
        score = float(row["score_risque"])
        item = {
            "personne": row["nom"],
            "type": row["type"],
            "score_risque": score,
            "niveau": risk_level(score),
            "description": row["description"],
            "explication": case_explanation(row),
        }
        if score >= 0.70:
            item["recommandation"] = (
                "Audit approfondi et gel des transactions"
                if score >= 0.80
                else "Surveillance renforcée"
            )
            report["alertes"].append(item)
        elif score >= 0.40:
            item["recommandation"] = "Vérification documentaire"
            report["detections"].append(item)

    REPORT_FILE.write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"Rapport consolidé généré: {REPORT_FILE}")
    print(f"Alertes: {len(report['alertes'])} | Détections: {len(report['detections'])}")
    return report


def main() -> int:
    print("=== LANDGUARD - PIPELINE COMPLET ===")
    df = load_dataset()
    write_dataset_facts(df)
    prolog_output = run_symbolic_pipeline()
    problog_output = run_probabilistic_pipeline()
    deepproblog_output = run_neurosymbolic_pipeline()
    generate_report(df, prolog_output, problog_output, deepproblog_output)
    print("Pipeline terminé.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
