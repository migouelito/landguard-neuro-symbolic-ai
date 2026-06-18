"""LandGuard Streamlit demo platform."""

from __future__ import annotations

import json
import shutil
import subprocess
from pathlib import Path

import pandas as pd
import streamlit as st


ROOT_DIR = Path(__file__).resolve().parent
DATA_FILE = ROOT_DIR / "data" / "dataset.csv"
REPORT_FILE = ROOT_DIR / "rapport_final.json"
PIPELINE_SCRIPT = ROOT_DIR / "scripts" / "run_local_pipeline.sh"
PROJECT_REPORT = ROOT_DIR / "rapport_projet.pdf"
CONCEPT_DIAGRAM = ROOT_DIR / "diagramme_concepts.pdf"
PROBLOG_REPORT = ROOT_DIR / "prolog" / "rapport_inference_prob.txt"
DL_DOC = ROOT_DIR / "description_logic.md"
README = ROOT_DIR / "README.md"
VENV_BIN = ROOT_DIR / ".venv" / "bin"

RISK_ORDER = ["standard", "limite", "speculation", "accaparement", "fraude_sophistiquee"]
RISK_COLORS = {
    "standard": "#15803d",
    "limite": "#b7791f",
    "speculation": "#c05621",
    "accaparement": "#6d5bd0",
    "fraude_sophistiquee": "#b42318",
}


def find_tool(command: str) -> str | None:
    """Return a command path from PATH or the project virtual environment."""
    system_path = shutil.which(command)
    if system_path:
        return system_path
    venv_path = VENV_BIN / command
    if venv_path.exists():
        return str(venv_path)
    return None


st.set_page_config(
    page_title="LandGuard AI",
    page_icon="LG",
    layout="wide",
    initial_sidebar_state="expanded",
)


def inject_css() -> None:
    st.markdown(
        """
        <style>
        :root {
            --bg: #f5f7fb;
            --panel: #ffffff;
            --panel-2: #f8fafc;
            --line: #d9e2ec;
            --text: #17202a;
            --muted: #64748b;
            --accent: #0f766e;
            --accent-2: #b7791f;
            --green: #15803d;
            --yellow: #b7791f;
            --red: #b42318;
        }
        .stApp {
            background:
                linear-gradient(180deg, rgba(15, 118, 110, .06), transparent 270px),
                var(--bg);
            color: var(--text);
        }
        [data-testid="stSidebar"] {
            background: #f9fafb;
            border-right: 1px solid var(--line);
        }
        [data-testid="stSidebar"] * {
            color: var(--text);
        }
        [data-testid="stMetric"] {
            background: var(--panel);
            border: 1px solid var(--line);
            border-radius: 8px;
            padding: 16px 18px;
            min-height: 110px;
            box-shadow: 0 10px 30px rgba(15, 23, 42, .06);
        }
        [data-testid="stMetricLabel"] {
            color: var(--muted);
        }
        [data-testid="stMetricValue"] {
            color: var(--text);
        }
        .hero {
            border: 1px solid var(--line);
            background:
                linear-gradient(135deg, rgba(15, 118, 110, .10), rgba(255, 255, 255, .96)),
                var(--panel);
            border-radius: 8px;
            padding: 22px 24px;
            margin-bottom: 18px;
            box-shadow: 0 16px 45px rgba(15, 23, 42, .07);
        }
        .hero h1 {
            font-size: 2.2rem;
            margin: 0 0 8px 0;
            letter-spacing: 0;
        }
        .hero p {
            color: var(--muted);
            margin: 0;
            font-size: 1rem;
        }
        .status-pill {
            display: inline-block;
            border-radius: 999px;
            border: 1px solid var(--line);
            padding: 5px 10px;
            margin: 3px 5px 3px 0;
            font-size: .82rem;
            color: #0f766e;
            background: #ecfdf5;
        }
        .card {
            border: 1px solid var(--line);
            background: var(--panel);
            border-radius: 8px;
            padding: 18px;
            box-shadow: 0 8px 24px rgba(15, 23, 42, .05);
        }
        .risk-high {
            color: var(--red);
            font-weight: 700;
        }
        .risk-mid {
            color: var(--yellow);
            font-weight: 700;
        }
        .risk-low {
            color: var(--green);
            font-weight: 700;
        }
        div[data-testid="stDataFrame"] {
            border: 1px solid var(--line);
            border-radius: 8px;
            overflow: hidden;
        }
        .stButton > button {
            border-radius: 8px;
            border: 1px solid rgba(15, 118, 110, .35);
            background: #0f766e;
            color: #ffffff;
            font-weight: 700;
        }
        .stButton > button:hover {
            border-color: #0f766e;
            background: #115e59;
            color: #ffffff;
        }
        .stDownloadButton > button {
            border-radius: 8px;
        }
        </style>
        """,
        unsafe_allow_html=True,
    )


@st.cache_data(show_spinner=False)
def load_dataset() -> pd.DataFrame:
    df = pd.read_csv(DATA_FILE)
    df["niveau"] = df["score_risque"].apply(risk_level)
    return df


@st.cache_data(show_spinner=False)
def load_report() -> dict:
    if not REPORT_FILE.exists():
        return {}
    return json.loads(REPORT_FILE.read_text(encoding="utf-8"))


def risk_level(score: float) -> str:
    if score >= 0.80:
        return "Critique"
    if score >= 0.60:
        return "Élevé"
    if score >= 0.30:
        return "Moyen"
    return "Faible"


def recommendation(score: float) -> str:
    if score >= 0.80:
        return "Audit approfondi, gel temporaire des transactions et contrôle documentaire prioritaire."
    if score >= 0.60:
        return "Surveillance renforcée et contrôle manuel du dossier."
    if score >= 0.30:
        return "Vérification documentaire simple."
    return "Aucune action immédiate."


def explain_case(row: pd.Series) -> list[str]:
    clues = []
    if row["nb_parcelles"] >= 4:
        clues.append(f"Accaparement potentiel: {int(row['nb_parcelles'])} parcelles détenues.")
    if row["frequence_revente"] >= 2:
        clues.append(f"Spéculation: {int(row['frequence_revente'])} reventes observées.")
    if row["plus_value"] > 0.5:
        clues.append(f"Plus-value anormale: {row['plus_value'] * 100:.0f}%.")
    if row["nb_liens_reseau"] >= 2:
        clues.append(f"Réseau suspect: {int(row['nb_liens_reseau'])} liens relationnels.")
    if row["partage_telephone"] == 1:
        clues.append("Indice prête-nom: téléphone partagé.")
    if row["partage_adresse"] == 1:
        clues.append("Indice prête-nom: adresse partagée.")
    if row["agent_public"] == 1:
        clues.append("Agent public impliqué: conflit d'intérêt possible.")
    return clues or ["Aucun signal fort détecté."]


def render_header() -> None:
    st.markdown(
        """
        <div class="hero">
            <h1>LandGuard Neuro-Symbolic AI</h1>
            <p>Plateforme de démonstration pour détecter, prioriser et expliquer les risques de fraude foncière.</p>
        </div>
        """,
        unsafe_allow_html=True,
    )


def render_sidebar() -> str:
    st.sidebar.title("LandGuard")
    st.sidebar.caption("Console de soutenance")
    page = st.sidebar.radio(
        "Navigation",
        ["Vue générale", "Analyse dossiers", "Pipeline", "Livrables", "Documentation"],
    )

    st.sidebar.divider()
    st.sidebar.subheader("Environnement")
    swipl = "OK" if find_tool("swipl") else "absent"
    problog = "OK" if find_tool("problog") else "absent"
    st.sidebar.markdown(f'<span class="status-pill">SWI-Prolog: {swipl}</span>', unsafe_allow_html=True)
    st.sidebar.markdown(f'<span class="status-pill">ProbLog: {problog}</span>', unsafe_allow_html=True)
    st.sidebar.markdown(f'<span class="status-pill">Streamlit: OK</span>', unsafe_allow_html=True)

    st.sidebar.divider()
    st.sidebar.caption("Commande")
    st.sidebar.code(".venv/bin/python -m streamlit run streamlit_app.py", language="bash")
    return page


def render_metrics(df: pd.DataFrame, report: dict) -> None:
    alerts = len(report.get("alertes", []))
    critical = int((df["score_risque"] >= 0.80).sum())
    elevated = int((df["score_risque"] >= 0.60).sum())
    c1, c2, c3, c4, c5 = st.columns(5)
    c1.metric("Cas analysés", f"{len(df)}")
    c2.metric("Alertes rapport", f"{alerts}")
    c3.metric("Critiques", f"{critical}")
    c4.metric("Élevés +", f"{elevated}")
    c5.metric("Score moyen", f"{df['score_risque'].mean():.2f}")


def render_overview(df: pd.DataFrame, report: dict) -> None:
    render_header()
    render_metrics(df, report)

    left, right = st.columns([1.15, 1])
    with left:
        st.subheader("Répartition des cas")
        counts = df["type"].value_counts().reindex(RISK_ORDER).dropna()
        st.bar_chart(counts, color="#0f766e", height=280)

        st.subheader("Distribution des scores")
        bins = pd.cut(df["score_risque"], bins=[0, 0.3, 0.6, 0.8, 1.0], labels=["Faible", "Moyen", "Élevé", "Critique"], include_lowest=True)
        st.bar_chart(bins.value_counts().reindex(["Faible", "Moyen", "Élevé", "Critique"]), color="#b7791f", height=230)

    with right:
        st.subheader("Alertes prioritaires")
        alerts = report.get("alertes", [])
        if alerts:
            for alert in alerts[:7]:
                score = alert.get("score_risque", 0.0)
                st.markdown(
                    f"""
                    <div class="card">
                        <b>{alert.get('personne')}</b><br>
                        <span class="risk-high">{alert.get('niveau')}</span> · score {score:.2f}<br>
                        <span style="color:#64748b">{alert.get('description', '-')}</span>
                    </div>
                    """,
                    unsafe_allow_html=True,
                )
                st.write("")
        else:
            st.info("Aucun rapport chargé. Lance le pipeline pour générer les alertes.")


def render_case_analysis(df: pd.DataFrame) -> None:
    st.title("Analyse des dossiers")

    filters = st.columns([1, 1, 1.2, 1])
    selected_types = filters[0].multiselect("Types", RISK_ORDER, default=RISK_ORDER)
    min_score, max_score = filters[1].slider("Score", 0.0, 1.0, (0.0, 1.0), 0.01)
    search = filters[2].text_input("Recherche", placeholder="Nom, type, description...")
    sort_mode = filters[3].selectbox("Tri", ["Score décroissant", "Score croissant", "ID croissant"])

    filtered = df[df["type"].isin(selected_types)]
    filtered = filtered[(filtered["score_risque"] >= min_score) & (filtered["score_risque"] <= max_score)]
    if search:
        needle = search.lower()
        filtered = filtered[
            filtered["nom"].str.lower().str.contains(needle, na=False)
            | filtered["type"].str.lower().str.contains(needle, na=False)
            | filtered["description"].str.lower().str.contains(needle, na=False)
        ]

    if sort_mode == "Score décroissant":
        filtered = filtered.sort_values("score_risque", ascending=False)
    elif sort_mode == "Score croissant":
        filtered = filtered.sort_values("score_risque", ascending=True)
    else:
        filtered = filtered.sort_values("id", ascending=True)

    st.caption(f"{len(filtered)} dossier(s) affiché(s)")
    table_cols = ["id", "nom", "type", "score_risque", "niveau", "description"]
    st.dataframe(
        filtered[table_cols],
        use_container_width=True,
        height=360,
        hide_index=True,
        column_config={
            "score_risque": st.column_config.ProgressColumn("Score", min_value=0.0, max_value=1.0, format="%.2f"),
            "niveau": "Niveau",
        },
    )

    st.divider()
    if filtered.empty:
        st.warning("Aucun dossier ne correspond aux filtres.")
        return

    options = filtered["nom"].tolist()
    selected_name = st.selectbox("Dossier à présenter", options)
    row = filtered[filtered["nom"] == selected_name].iloc[0]
    render_case_detail(row)


def render_case_detail(row: pd.Series) -> None:
    score = float(row["score_risque"])
    left, right = st.columns([1, 1])

    with left:
        st.subheader(f"{row['nom']}")
        st.progress(score, text=f"Score de risque: {score:.2f} · {risk_level(score)}")
        st.markdown(
            f"""
            <div class="card">
                <b>Type</b>: {row['type']}<br>
                <b>Description</b>: {row['description']}<br>
                <b>Recommandation</b>: {recommendation(score)}
            </div>
            """,
            unsafe_allow_html=True,
        )

    with right:
        st.subheader("Indices XAI")
        for clue in explain_case(row):
            st.markdown(f"- {clue}")

    st.subheader("Variables du dossier")
    variables = pd.DataFrame(
        [
            ("Parcelles", row["nb_parcelles"]),
            ("Parcelles urbaines", row["parcelles_urbaines"]),
            ("Parcelles rurales", row["parcelles_rurales"]),
            ("Fréquence revente", row["frequence_revente"]),
            ("Plus-value", f"{row['plus_value'] * 100:.0f}%"),
            ("Liens réseau", row["nb_liens_reseau"]),
            ("Téléphone partagé", "Oui" if row["partage_telephone"] else "Non"),
            ("Adresse partagée", "Oui" if row["partage_adresse"] else "Non"),
            ("Agent public", "Oui" if row["agent_public"] else "Non"),
        ],
        columns=["Indicateur", "Valeur"],
    )
    st.dataframe(variables, use_container_width=True, hide_index=True)


def run_pipeline() -> tuple[int, str]:
    process = subprocess.run(
        ["bash", str(PIPELINE_SCRIPT)],
        cwd=ROOT_DIR,
        capture_output=True,
        text=True,
        check=False,
        timeout=120,
    )
    output = (process.stdout or "") + ("\n" + process.stderr if process.stderr else "")
    return process.returncode, output


def render_pipeline() -> None:
    st.title("Pipeline d'orchestration")
    st.caption("Exécute main.py, génère les faits Prolog, lance les contrôles disponibles et produit rapport_final.json.")

    col1, col2, col3 = st.columns(3)
    col1.metric("Script", PIPELINE_SCRIPT.name if PIPELINE_SCRIPT.exists() else "manquant")
    has_swipl = find_tool("swipl") is not None
    has_problog = find_tool("problog") is not None
    col2.metric("SWI-Prolog", "OK" if has_swipl else "optionnel absent")
    col3.metric("ProbLog", "OK" if has_problog else "optionnel absent")

    if not has_swipl:
        st.info(
            "SWI-Prolog n'est pas installé sur cette machine. La démo continue quand même: "
            "le pipeline Python, le dataset et le rapport XAI restent exécutables; seuls les smoke tests Prolog sont ignorés."
        )

    if st.button("Lancer le pipeline complet", type="primary"):
        with st.spinner("Pipeline en cours..."):
            try:
                code, output = run_pipeline()
                st.session_state["last_pipeline_output"] = output
                st.session_state["last_pipeline_code"] = code
                st.cache_data.clear()
            except subprocess.TimeoutExpired:
                st.session_state["last_pipeline_output"] = "Timeout: le pipeline a dépassé 120 secondes."
                st.session_state["last_pipeline_code"] = 124

    code = st.session_state.get("last_pipeline_code")
    output = st.session_state.get("last_pipeline_output", "Aucune exécution dans cette session.")
    if code is not None:
        if code == 0:
            st.success("Pipeline terminé avec succès.")
        else:
            st.error(f"Pipeline terminé avec le code {code}.")
    st.code(output, language="text")


def render_deliverables(report: dict) -> None:
    st.title("Livrables")
    st.caption("Accès rapide aux fichiers attendus par l'énoncé.")

    deliverables = [
        ("Rapport consolidé JSON", REPORT_FILE, "application/json"),
        ("Rapport projet PDF", PROJECT_REPORT, "application/pdf"),
        ("Diagramme concepts PDF", CONCEPT_DIAGRAM, "application/pdf"),
        ("Rapport ProbLog", PROBLOG_REPORT, "text/plain"),
        ("Dataset CSV", DATA_FILE, "text/csv"),
    ]

    for title, path, mime in deliverables:
        c1, c2, c3 = st.columns([2, 1, 1])
        c1.markdown(f"**{title}**")
        c2.write("OK" if path.exists() else "Manquant")
        if path.exists():
            c3.download_button(
                "Télécharger",
                data=path.read_bytes(),
                file_name=path.name,
                mime=mime,
                key=f"download-{path.name}",
            )
        else:
            c3.write("-")

    st.divider()
    st.subheader("Résumé du rapport")
    if not report:
        st.info("Le rapport JSON n'est pas encore disponible.")
        return
    st.json(
        {
            "meta": report.get("meta", {}),
            "dataset": report.get("dataset", {}),
            "nb_alertes": len(report.get("alertes", [])),
            "nb_detections": len(report.get("detections", [])),
        }
    )


def render_docs() -> None:
    st.title("Documentation technique")
    tab1, tab2, tab3 = st.tabs(["README", "Description Logic", "ProbLog"])
    with tab1:
        st.markdown(README.read_text(encoding="utf-8") if README.exists() else "README manquant.")
    with tab2:
        st.markdown(DL_DOC.read_text(encoding="utf-8") if DL_DOC.exists() else "Document DL manquant.")
    with tab3:
        st.code((ROOT_DIR / "prolog" / "probabilistic_rules.pl").read_text(encoding="utf-8"), language="prolog")


def main() -> None:
    inject_css()
    page = render_sidebar()
    df = load_dataset()
    report = load_report()

    if page == "Vue générale":
        render_overview(df, report)
    elif page == "Analyse dossiers":
        render_case_analysis(df)
    elif page == "Pipeline":
        render_pipeline()
    elif page == "Livrables":
        render_deliverables(report)
    else:
        render_docs()


if __name__ == "__main__":
    main()
