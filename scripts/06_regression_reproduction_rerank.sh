#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ORCALOCA_DIR="${ORCALOCA_DIR:-$ROOT_DIR/work/OrcaLoca}"
AGENTLESS_DIR="${AGENTLESS_DIR:-$ORCALOCA_DIR/third_party/Agentless}"
AGENTLESS_RUNTIME="${AGENTLESS_RUNTIME:-$ROOT_DIR/work/agentless_runtime}"
AGENTLESS_OUTPUT_DIR="${AGENTLESS_OUTPUT_DIR:-$ROOT_DIR/work/agentless_outputs/repair_verified50_seed20260713_claude_s40_strreplace}"
IDS_FILE="${IDS_FILE:-$ROOT_DIR/artifacts/verified50/verified50_seed20260713_instance_ids.txt}"
REPRO_TESTS="${REPRO_TESTS:-$ROOT_DIR/work/reproduction_test_rerank/reproduction_tests/selected_reproduction_tests.jsonl}"
WORK_DIR="${WORK_DIR:-$ROOT_DIR/work/paper_aligned_rerank}"
REG_SELECT_DIR="${REG_SELECT_DIR:-$WORK_DIR/select_regression}"
PASSING_TESTS="${PASSING_TESTS:-$WORK_DIR/passing_tests.jsonl}"
OUTPUT_FILE="${RERANK_OUTPUT_FILE:-$WORK_DIR/all_preds_regression_reproduction_rerank.jsonl}"
PYTHON_BIN="${PYTHON_BIN:-python3}"
REG_SELECT_MODEL="${REG_SELECT_MODEL:-gpt-5.4-mini}"
REG_SELECT_BACKEND="${REG_SELECT_BACKEND:-openai}"
TEST_NUM_WORKERS="${TEST_NUM_WORKERS:-2}"
TEST_TIMEOUT="${TEST_TIMEOUT:-1800}"

export PYTHONPATH="$AGENTLESS_DIR:${PYTHONPATH:-}"
mkdir -p "$AGENTLESS_RUNTIME" "$WORK_DIR" "$REG_SELECT_DIR"

if [ ! -f "$REPRO_TESTS" ]; then
  echo "Missing selected reproduction tests: $REPRO_TESTS" >&2
  echo "Run reproduction-test generation/validation before this paper-aligned rerank step." >&2
  exit 1
fi

IDS_ARGS=()
while IFS= read -r line; do
  [ -n "$line" ] && IDS_ARGS+=("$line")
done < "$IDS_FILE"

missing=0
for i in $(seq 0 39); do
  for suffix in processed reproduction_test_results; do
    path="$AGENTLESS_OUTPUT_DIR/output_${i}_${suffix}.jsonl"
    if [ ! -f "$path" ]; then
      echo "Missing required candidate file: $path" >&2
      missing=1
    fi
  done
done
if [ "$missing" -ne 0 ]; then
  exit 1
fi

cd "$AGENTLESS_RUNTIME"

"$PYTHON_BIN" "$AGENTLESS_DIR/agentless/test/run_regression_tests.py" \
  --dataset princeton-nlp/SWE-bench_Verified \
  --run_id orcaloca_verified50_regression_base_tests \
  --output_file "$PASSING_TESTS" \
  --num_workers "$TEST_NUM_WORKERS" \
  --timeout "$TEST_TIMEOUT" \
  --instance_ids "${IDS_ARGS[@]}"

"$PYTHON_BIN" "$AGENTLESS_DIR/agentless/test/select_regression_tests.py" \
  --dataset princeton-nlp/SWE-bench_Verified \
  --passing_tests "$PASSING_TESTS" \
  --output_folder "$REG_SELECT_DIR" \
  --model "$REG_SELECT_MODEL" \
  --backend "$REG_SELECT_BACKEND" \
  --instance_ids "${IDS_ARGS[@]}"

for i in $(seq 0 39); do
  "$PYTHON_BIN" "$AGENTLESS_DIR/agentless/test/run_regression_tests.py" \
    --dataset princeton-nlp/SWE-bench_Verified \
    --regression_tests "$REG_SELECT_DIR/output.jsonl" \
    --predictions_path "$AGENTLESS_OUTPUT_DIR/output_${i}_processed.jsonl" \
    --run_id "orcaloca_verified50_regression_rerank_candidate_${i}" \
    --num_workers "$TEST_NUM_WORKERS" \
    --timeout "$TEST_TIMEOUT" \
    --instance_ids "${IDS_ARGS[@]}"
done

"$PYTHON_BIN" "$AGENTLESS_DIR/agentless/repair/rerank.py" \
  --patch_folder "$AGENTLESS_OUTPUT_DIR" \
  --num_samples 40 \
  --deduplicate \
  --regression \
  --reproduction \
  --output_file "$OUTPUT_FILE"

echo "Wrote $OUTPUT_FILE"
