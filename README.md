# OrcaLoca SWE-bench Verified Reproduction

This repository packages a fixed 50-instance SWE-bench Verified reproduction of the OrcaLoca localization pipeline integrated with Agentless repair and the official SWE-bench harness.

It is a reproduction artifact, not a fork intended to replace upstream OrcaLoca or Agentless. The repository contains:

- patches and overlay files for the local code changes used in the run;
- shell scripts for the main pipeline stages;
- the fixed Verified50 sample metadata;
- localization, repair, rerank, and official evaluation outputs needed to inspect the reported result.

## Result

Dataset: `princeton-nlp/SWE-bench_Verified`, split `test`

Sample: fixed seed `20260713`, repo-stratified 50 instances.

| Metric | Result |
| --- | ---: |
| File Match | 38/50 = 76.00% |
| Function Match | 29/50 = 58.00% |
| Resolved Rate | 20/50 = 40.00% |
| Official reports | 49/50 |
| Empty patch | 1/50 |
| Docker infra errors after retry | 0 |

The one missing official report is the empty-patch instance `sphinx-doc__sphinx-9258`. It is counted as unresolved in the conservative 20/50 resolved rate.

## Configuration

Localization:

- OrcaLoca search/localization
- Model: `gpt-5.4-mini`
- Backend: OpenAI-compatible API

Repair:

- Agentless repair
- Model: `claude-haiku-4-5-20251001`
- Backend: Anthropic-compatible API
- Settings: `max_samples=40`, `top_n=3`, `context_window=10`, `--loc_interval`, `--cot`, `--str_replace_format`

Patch selection:

- Agentless lightweight rerank with `--deduplicate`
- Regression/reproduction-test rerank was not run for this release

Official evaluation:

- `swebench.harness.run_evaluation`
- Dataset: `princeton-nlp/SWE-bench_Verified`
- Split: `test`
- Conservative final result after retrying transient Docker build/export failures

## Repository Layout

```text
patches/
  orcaloca_verified_support.patch
  agentless_verified_repair.patch
overlays/
  OrcaLoca/
  Agentless/
scripts/
  00_clone_and_patch.sh
  01_run_orcaloca_search.sh
  02_prepare_agentless_loc.sh
  03_run_agentless_repair_claude_s40.sh
  04_lightweight_rerank.sh
  05_run_swebench_eval.sh
  summarize_results.py
configs/
  env.example
  key.cfg.example
artifacts/verified50/
  verified50_seed20260713_instance_ids.txt
  verified50_seed20260713_metadata.json
  localization_metrics.json
  loc_orcar_outputs.jsonl
  all_preds_lightweight.jsonl
  verified50_claude_s40_lightweight_summary.json
  eval_reports/
docs/
  reproduction_report.md
  implementation_notes.md
```

## API Environment

Do not put API keys in code. The scripts read keys from environment variables.

OpenAI-compatible variables:

- `OPENAI_API_KEY`
- `OPENAI_BASE_URL`
- `BASE_URL`
- `API_BASE_URL`
- `OPENAI_API_BASE`

Base URL priority:

```text
OPENAI_BASE_URL > BASE_URL > API_BASE_URL > OPENAI_API_BASE
```

Anthropic-compatible variables:

- `ANTHROPIC_API_KEY`
- `ANTHROPIC_BASE_URL`

Copy the template and fill it locally:

```bash
cp configs/env.example .env
$EDITOR .env
set -a
source .env
set +a
```

The release artifacts do not contain API keys or provider-specific private credentials.

## Reproducing the Pipeline

The commands below assume Linux x86_64, Docker, Conda/Mamba, and Python 3.10 or 3.11 environments for OrcaLoca and Agentless.

Clone upstream OrcaLoca and apply the patches:

```bash
export WORKDIR=$PWD/work
bash scripts/00_clone_and_patch.sh
```

Run OrcaLoca search on the fixed Verified50 instance list:

```bash
export ORCALOCA_DIR=$PWD/work/OrcaLoca
export ORCAR_CACHE_DIR=$PWD/work/orcar_cache
bash scripts/01_run_orcaloca_search.sh
```

Prepare Agentless localization input:

```bash
bash scripts/02_prepare_agentless_loc.sh
```

Run Agentless repair with Claude-compatible backend:

```bash
export AGENTLESS_DIR=$ORCALOCA_DIR/third_party/Agentless
export AGENTLESS_OUTPUT_DIR=$PWD/work/agentless_outputs/repair_verified50_seed20260713_claude_s40_strreplace
bash scripts/03_run_agentless_repair_claude_s40.sh
```

Run lightweight rerank:

```bash
bash scripts/04_lightweight_rerank.sh
```

Run official SWE-bench evaluation:

```bash
bash scripts/05_run_swebench_eval.sh
```

Summarize results:

```bash
python3 scripts/summarize_results.py \
  --predictions artifacts/verified50/all_preds_lightweight.jsonl \
  --reports artifacts/verified50/eval_reports \
  --instance-ids artifacts/verified50/verified50_seed20260713_instance_ids.txt
```

## Included Artifacts

The included artifacts are intentionally compact:

- final instance IDs and sampling metadata;
- the prepared Agentless loc file;
- final selected patches used for official evaluation;
- official SWE-bench report JSON files;
- compact patch-only examples.

Full repo caches, Hugging Face caches, Docker layers, tmux logs, API environment files, and raw repair logs are not included.

## Important Caveats

This run is numerically close to the OrcaLoca paper's SWE-bench Lite resolved headline, but it is not a strict same-dataset comparison. The paper reports its main resolved result on SWE-bench Lite 300, while this artifact uses a fixed 50-instance sample from SWE-bench Verified.

The repair stage is closer to the paper-style Agentless setup than earlier OpenAI-compatible `diff_format` experiments because it uses Claude-compatible repair and `str_replace_format`. However, this release uses lightweight rerank, not the full Agentless regression/reproduction-test rerank.

## Upstream Sources

- OrcaLoca: https://github.com/fishmingyu/OrcaLoca
- Agentless: https://github.com/OpenAutoCoder/Agentless
- SWE-bench: https://github.com/swe-bench/SWE-bench
