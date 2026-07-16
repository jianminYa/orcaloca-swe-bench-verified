#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ORCALOCA_DIR="${ORCALOCA_DIR:-$ROOT_DIR/work/OrcaLoca}"
AGENTLESS_DIR="${AGENTLESS_DIR:-$ORCALOCA_DIR/third_party/Agentless}"
AGENTLESS_RUNTIME="${AGENTLESS_RUNTIME:-$ROOT_DIR/work/agentless_runtime}"
AGENTLESS_OUTPUT_DIR="${AGENTLESS_OUTPUT_DIR:-$ROOT_DIR/work/agentless_outputs/repair_verified50_seed20260713_claude_s40_strreplace}"
OUTPUT_FILE="${RERANK_OUTPUT_FILE:-$AGENTLESS_OUTPUT_DIR/all_preds_lightweight.jsonl}"
PYTHON_BIN="${PYTHON_BIN:-python3}"

export PYTHONPATH="$AGENTLESS_DIR:${PYTHONPATH:-}"
mkdir -p "$AGENTLESS_RUNTIME"
cd "$AGENTLESS_RUNTIME"

"$PYTHON_BIN" "$AGENTLESS_DIR/agentless/repair/rerank.py" \
  --patch_folder "$AGENTLESS_OUTPUT_DIR" \
  --num_samples 40 \
  --deduplicate \
  --output_file "$OUTPUT_FILE"

echo "Wrote $OUTPUT_FILE"
