import json
import shutil
import subprocess
import sys
import unittest
from pathlib import Path

import pandas as pd


ROOT = Path(__file__).resolve().parents[1]


class LandGuardEndToEndTests(unittest.TestCase):
    def test_dataset_has_required_shape_and_categories(self):
        df = pd.read_csv(ROOT / "data" / "dataset.csv")

        self.assertGreaterEqual(len(df), 50)
        expected_columns = {
            "id",
            "nom",
            "type",
            "nb_parcelles",
            "frequence_revente",
            "plus_value",
            "nb_liens_reseau",
            "partage_telephone",
            "partage_adresse",
            "score_risque",
        }
        self.assertTrue(expected_columns.issubset(df.columns))

        counts = df["type"].value_counts().to_dict()
        self.assertGreaterEqual(counts.get("standard", 0), 30)
        self.assertGreaterEqual(counts.get("speculation", 0), 5)
        self.assertGreaterEqual(counts.get("accaparement", 0), 5)
        self.assertGreaterEqual(counts.get("limite", 0), 5)
        self.assertGreaterEqual(counts.get("fraude_sophistiquee", 0), 5)

    def test_main_pipeline_produces_consolidated_report_when_dependencies_exist(self):
        result = subprocess.run(
            [sys.executable, "main.py"],
            cwd=ROOT,
            capture_output=True,
            text=True,
            timeout=60,
        )

        self.assertEqual(result.returncode, 0, result.stderr)
        report_path = ROOT / "rapport_final.json"
        self.assertTrue(report_path.exists())

        report = json.loads(report_path.read_text(encoding="utf-8"))
        self.assertEqual(report["meta"]["systeme"], "LandGuard Neuro-Symbolic AI")
        self.assertGreaterEqual(report["dataset"]["total_cas"], 50)
        self.assertIn("alertes", report)

    @unittest.skipIf(shutil.which("swipl") is None, "SWI-Prolog absent")
    def test_symbolic_prolog_tests(self):
        result = subprocess.run(
            ["swipl", "-q", "-s", "tests/test_prolog.pl"],
            cwd=ROOT,
            capture_output=True,
            text=True,
            timeout=30,
        )

        self.assertEqual(result.returncode, 0, result.stderr)

    @unittest.skipIf(shutil.which("problog") is None, "ProbLog absent")
    def test_probabilistic_queries(self):
        result = subprocess.run(
            ["problog", "tests/test_probabilistic.pl"],
            cwd=ROOT,
            capture_output=True,
            text=True,
            timeout=30,
        )

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("risque_fraude(abdou)", result.stdout)


if __name__ == "__main__":
    unittest.main()
