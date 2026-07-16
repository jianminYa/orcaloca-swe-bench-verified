#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ORCALOCA_DIR="${ORCALOCA_DIR:-$ROOT_DIR/work/OrcaLoca}"
OUTPUT_DIR="${ORCALOCA_OUTPUT_DIR:-$ROOT_DIR/work/orcaloca_output}"
LOG_DIR="${ORCALOCA_LOG_DIR:-$ROOT_DIR/work/orcaloca_log}"
KEY_CFG="${KEY_CFG:-$ORCALOCA_DIR/key.cfg}"
MODEL="${ORCALOCA_MODEL:-gpt-5.4-mini}"
IDS_FILE="${IDS_FILE:-$ROOT_DIR/artifacts/verified50/verified50_seed20260713_instance_ids.txt}"
ORCAR_CACHE_DIR="${ORCAR_CACHE_DIR:-$ROOT_DIR/work/orcar_cache}"
PYTHON_BIN="${PYTHON_BIN:-python3}"

if [ -z "${OPENAI_API_KEY:-}" ]; then
  echo "ERROR: OPENAI_API_KEY is not set." >&2
  exit 1
fi

BASE_URL_EFFECTIVE="${OPENAI_BASE_URL:-${BASE_URL:-${API_BASE_URL:-${OPENAI_API_BASE:-}}}}"
umask 077
cat > "$KEY_CFG" <<EOF
OPENAI_API_KEY=${OPENAI_API_KEY}
OPENAI_BASE_URL=${BASE_URL_EFFECTIVE}
BASE_URL=${BASE_URL_EFFECTIVE}
API_BASE_URL=${BASE_URL_EFFECTIVE}
OPENAI_API_BASE=${BASE_URL_EFFECTIVE}
EOF

mkdir -p "$OUTPUT_DIR" "$ORCAR_CACHE_DIR"
cd "$ORCALOCA_DIR"

"$PYTHON_BIN" evaluation/run.py \
  -cfg "$KEY_CFG" \
  -m "$MODEL" \
  -d princeton-nlp/SWE-bench_Verified \
  --final_stage search \
  --instance_ids $(tr '\n' ' ' < "$IDS_FILE")

rm -rf "$OUTPUT_DIR" "$LOG_DIR"
cp -a output "$OUTPUT_DIR"
cp -a log "$LOG_DIR"
echo "Copied OrcaLoca output to $OUTPUT_DIR"
echo "Copied OrcaLoca logs to $LOG_DIR"
