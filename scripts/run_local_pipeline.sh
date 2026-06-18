#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

PYTHON_BIN="python3"
if [ -x ".venv/bin/python" ]; then
  PYTHON_BIN=".venv/bin/python"
elif ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required but was not found in PATH" >&2
  exit 1
fi

HAS_SWIPL=0
if command -v swipl >/dev/null 2>&1; then
  HAS_SWIPL=1
else
  echo "[info] SWI-Prolog is not installed. Prolog smoke tests will be skipped."
fi

echo "[1/3] Running LandGuard main pipeline"
"$PYTHON_BIN" main.py

echo "[2/3] Prolog smoke test on dataset facts"
if [ "$HAS_SWIPL" -eq 1 ]; then
  swipl -q \
    -g "['prolog/dataset_facts.pl','prolog/rules.pl'], findall(N, cas_dataset_critique(N), Critiques), length(Critiques, NB_Critiques), format('Critical dataset cases: ~w~n', [NB_Critiques]), findall(N, cas_dataset_accaparement(N), Accaparements), length(Accaparements, NB_Accaparements), format('Accaparement cases: ~w~n', [NB_Accaparements]), halt."
else
  echo "Skipped: swipl not found in PATH."
fi

echo "[3/3] Report checks"
"$PYTHON_BIN" - <<'PY'
from pathlib import Path
required = [Path('rapport_final.json'), Path('prolog/dataset_facts.pl')]
missing = [str(path) for path in required if not path.exists()]
if missing:
    raise SystemExit(f"Missing expected output files: {missing}")
print('All expected output files are present.')
PY

echo "Done."
