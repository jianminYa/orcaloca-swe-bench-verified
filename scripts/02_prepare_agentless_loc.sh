#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ORCALOCA_DIR="${ORCALOCA_DIR:-$ROOT_DIR/work/OrcaLoca}"
ORCALOCA_OUTPUT_DIR="${ORCALOCA_OUTPUT_DIR:-$ROOT_DIR/work/orcaloca_output}"
AGENTLESS_OUTPUT_ROOT="${AGENTLESS_OUTPUT_ROOT:-$ROOT_DIR/work/agentless_outputs}"
AGENTLESS_DIR="${AGENTLESS_DIR:-$ORCALOCA_DIR/third_party/Agentless}"
IDS_FILE="${IDS_FILE:-$ROOT_DIR/artifacts/verified50/verified50_seed20260713_instance_ids.txt}"
REGEX_FILE="$AGENTLESS_OUTPUT_ROOT/verified50_instance_regex.txt"
PYTHON_BIN="${PYTHON_BIN:-python3}"

mkdir -p "$AGENTLESS_OUTPUT_ROOT"
paste -sd'|' "$IDS_FILE" > "$REGEX_FILE"

cd "$ORCALOCA_DIR"

"$PYTHON_BIN" evaluation/process_output.py \
  -d princeton-nlp/SWE-bench_Verified \
  -f "$(cat "$REGEX_FILE")" \
  -s test \
  --output_dir "$ORCALOCA_OUTPUT_DIR"

"$PYTHON_BIN" evaluation/orcar_agentless/prepare_agentless.py \
  -d princeton-nlp/SWE-bench_Verified \
  -f "$(cat "$REGEX_FILE")" \
  -a "$AGENTLESS_DIR"

mkdir -p "$AGENTLESS_OUTPUT_ROOT/results/swe-bench-lite"
cp -a "$AGENTLESS_DIR/results/swe-bench-lite/edit_location_individual" \
  "$AGENTLESS_OUTPUT_ROOT/results/swe-bench-lite/"
cp -a "$AGENTLESS_DIR/target_inst_ids.json" "$AGENTLESS_OUTPUT_ROOT/target_inst_ids.json"

echo "Prepared Agentless output root: $AGENTLESS_OUTPUT_ROOT"
