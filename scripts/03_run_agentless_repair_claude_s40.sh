#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ORCALOCA_DIR="${ORCALOCA_DIR:-$ROOT_DIR/work/OrcaLoca}"
AGENTLESS_DIR="${AGENTLESS_DIR:-$ORCALOCA_DIR/third_party/Agentless}"
AGENTLESS_RUNTIME="${AGENTLESS_RUNTIME:-$ROOT_DIR/work/agentless_runtime}"
AGENTLESS_OUTPUT_ROOT="${AGENTLESS_OUTPUT_ROOT:-$ROOT_DIR/work/agentless_outputs}"
AGENTLESS_OUTPUT_DIR="${AGENTLESS_OUTPUT_DIR:-$AGENTLESS_OUTPUT_ROOT/repair_verified50_seed20260713_claude_s40_strreplace}"
IDS_FILE="${IDS_FILE:-$ROOT_DIR/artifacts/verified50/verified50_seed20260713_instance_ids.txt}"
TARGET_IDS_JSON="$AGENTLESS_OUTPUT_ROOT/target_inst_ids_verified50_seed20260713_dict.json"
LOC_FILE="${LOC_FILE:-$AGENTLESS_OUTPUT_ROOT/results/swe-bench-lite/edit_location_individual/loc_orcar_outputs.jsonl}"
MODEL="${ANTHROPIC_REPAIR_MODEL:-claude-haiku-4-5-20251001}"
PYTHON_BIN="${PYTHON_BIN:-python3}"

if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
  echo "ERROR: ANTHROPIC_API_KEY is not set." >&2
  exit 1
fi

mkdir -p "$AGENTLESS_RUNTIME" "$AGENTLESS_OUTPUT_DIR"

"$PYTHON_BIN" - <<PY
import json
from pathlib import Path
ids = [line.strip() for line in Path("$IDS_FILE").read_text().splitlines() if line.strip()]
Path("$TARGET_IDS_JSON").write_text(json.dumps({i: True for i in ids}, indent=2) + "\\n")
PY

export PYTHONPATH="$AGENTLESS_DIR:${PYTHONPATH:-}"
export AGENTLESS_TARGET_INST_IDS="$TARGET_IDS_JSON"

cd "$AGENTLESS_RUNTIME"

"$PYTHON_BIN" "$AGENTLESS_DIR/agentless/repair/repair.py" \
  --dataset princeton-nlp/SWE-bench_Verified \
  --loc_file "$LOC_FILE" \
  --output_folder "$AGENTLESS_OUTPUT_DIR" \
  --max_samples 40 \
  --loc_interval \
  --top_n 3 \
  --context_window 10 \
  --cot \
  --str_replace_format \
  --gen_and_process \
  --num_threads "${REPAIR_NUM_THREADS:-2}" \
  --model "$MODEL" \
  --backend anthropic
