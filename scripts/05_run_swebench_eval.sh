#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PREDICTIONS_PATH="${PREDICTIONS_PATH:-$ROOT_DIR/work/agentless_outputs/repair_verified50_seed20260713_claude_s40_strreplace/all_preds_lightweight.jsonl}"
IDS_FILE="${IDS_FILE:-$ROOT_DIR/artifacts/verified50/verified50_seed20260713_instance_ids.txt}"
RUN_ID="${RUN_ID:-orcaloca_verified50_seed20260713_claude_s40_lightweight}"
MAX_WORKERS="${MAX_WORKERS:-2}"
TIMEOUT="${TIMEOUT:-1800}"
PYTHON_BIN="${PYTHON_BIN:-python3}"

export HF_HOME="${HF_HOME:-$ROOT_DIR/work/hf}"
export HF_DATASETS_CACHE="${HF_DATASETS_CACHE:-$ROOT_DIR/work/hf_datasets}"

"$PYTHON_BIN" -m swebench.harness.run_evaluation \
  --dataset_name princeton-nlp/SWE-bench_Verified \
  --split test \
  --instance_ids $(tr '\n' ' ' < "$IDS_FILE") \
  --predictions_path "$PREDICTIONS_PATH" \
  --max_workers "$MAX_WORKERS" \
  --timeout "$TIMEOUT" \
  --cache_level env \
  --clean True \
  --run_id "$RUN_ID"
