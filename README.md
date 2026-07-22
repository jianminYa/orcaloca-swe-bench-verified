# OrcaLoca SWE-bench Verified Reproduction

This repository packages a fixed 50-instance SWE-bench Verified reproduction of the OrcaLoca localization pipeline integrated with Agentless repair and the official SWE-bench harness.

It is a reproduction artifact, not a fork intended to replace upstream OrcaLoca or Agentless. The repository contains:

- patches and overlay files for the local code changes used in the run;
- shell scripts for the main pipeline stages;
- the fixed Verified50 sample metadata;
- localization, repair, rerank, and official evaluation outputs needed to inspect the reported result.

The full patched source tree is published separately:

https://github.com/jianminYa/orcaloca-swe-bench-verified-code

## Result

Dataset: `princeton-nlp/SWE-bench_Verified`, split `test`

Sample: fixed seed `20260713`, repo-stratified 50 instances.

This is a Verified50 transfer reproduction, not the paper's original SWE-bench Lite 300 experiment.

Closest paper-aligned completed configuration in this artifact: OrcaLoca localization, Agentless repair with 40 candidates and `str_replace_format`, and Agentless regression+reproduction patch selection. It resolves `22/50 = 44.00%`.

The reproduction-test-only and lightweight rerank results are retained as ablations, not the final recommended number.

| Metric | Result |
| --- | ---: |
| File Match | 38/50 = 76.00% |
| Function Match | 29/50 = 58.00% |
| Resolved Rate, regression+reproduction rerank | 22/50 = 44.00% |
| Resolved Rate, reproduction-test rerank | 22/50 = 44.00% |
| Resolved Rate, lightweight rerank | 20/50 = 40.00% |
| Official harness evaluated non-empty patches | 49/50 |
| Empty patch | 1/50 |
| Docker infra errors after retry | 0 |

This does not mean 49 instances passed. It means the official SWE-bench harness evaluated 49 non-empty patches. The one unevaluated instance is the empty-patch instance `sphinx-doc__sphinx-9258`, and it is counted as unresolved in the conservative resolved-rate denominator.

Patch selection summary:

| Selection strategy | Tests used to select from 40 candidates | Resolved |
| --- | --- | ---: |
| Lightweight rerank | None; deduplication/Agentless lightweight selection only | 20/50 = 40.00% |
| Reproduction-only rerank | LLM-generated reproduction tests | 22/50 = 44.00% |
| Regression+reproduction rerank | Public Agentless regression validation plus reproduction tests | 22/50 = 44.00% |

Adding reproduction-test rerank improved the result from 20/50 to 22/50. Adding public Agentless regression validation did not change the resolved set on this Verified50 sample.

## Comparison to the OrcaLoca Paper

The OrcaLoca paper reports its headline result on SWE-bench Lite 300 with Claude 3.5 Sonnet and Agentless-1.5 repair integration. This artifact changes the dataset to a fixed 50-instance sample from SWE-bench Verified, so the numbers below are a transfer comparison rather than a same-dataset reproduction.

| Metric | OrcaLoca paper on SWE-bench Lite 300 | This artifact on SWE-bench Verified50 |
| --- | ---: | ---: |
| File Match | 250/300 = 83.33% | 38/50 = 76.00% |
| Function Match | 196/300 = 65.33% | 29/50 = 58.00% |
| Resolved Rate | 123/300 = 41.00% | 22/50 = 44.00% with closest paper-aligned regression+reproduction rerank |

The resolved-rate magnitude is close to the paper's Lite result, but the localization metrics are lower on this Verified50 sample. Because the dataset and models differ, this result should be interpreted as evidence that the OrcaLoca + Agentless-style pipeline transfers to Verified50, not as a replacement for the paper's SWE-bench Lite table.

Reference: OrcaLoca paper, Table 1 and Section 4.2.1, https://arxiv.org/abs/2502.00350.

## Configuration and Paper Alignment

The table below separates what was matched to the paper from what intentionally differs in this Verified50 run.

| Component | OrcaLoca paper setup | This artifact | Status | Likely impact |
| --- | --- | --- | --- | --- |
| Dataset | SWE-bench Lite 300, `test` split | SWE-bench Verified, fixed repo-stratified 50-instance sample, `test` split | Different by design | High |
| Localization method | OrcaLoca search/localization | OrcaLoca search/localization | Aligned | Low |
| Localization model | Claude 3.5 Sonnet | `gpt-5.4-mini` through an OpenAI-compatible backend | Different | Medium/high |
| Loc-to-repair bridge | OrcaLoca output converted to Agentless format | OrcaLoca output converted to Agentless `loc_file` format with Verified compatibility fixes | Workflow-aligned, implementation adapted | Medium |
| Repair framework | Agentless-1.5 repair integration | Public Agentless repair path | Framework-family aligned | Medium |
| Repair model | Claude 3.5 Sonnet | `claude-haiku-4-5-20251001` through an Anthropic-compatible backend | Different, but Claude-family | Medium |
| Repair sampling and context | 40 patches, `str_replace_format`, Agentless repair configuration | `max_samples=40`, `top_n=3`, `context_window=10`, `--loc_interval`, `--cot`, `--str_replace_format` | Mostly aligned | Low/medium |
| Patch selection | Regression and reproduction tests select among 40 candidates | `--regression --reproduction --deduplicate` | Closest public workflow alignment | Medium; see caveat below |
| Official evaluation | SWE-bench official harness | `swebench.harness.run_evaluation` on Verified50 | Evaluator aligned, dataset different | Low for evaluator, high for comparability |

The OrcaLoca paper does describe the key resolved-stage setup: OrcaLoca output is converted to Agentless format; Agentless Repair, Patch Validation, and Patch Selection are integrated; Claude-3.5-Sonnet-20241022 is used; 40 patches are generated with `str_replace_format`; both regression and reproduction tests are used for patch validation and final candidate selection. The upstream OrcaLoca repository also points users from `evaluation/process_output.py` to `evaluation/orcar_agentless/README.md` and `third_party/Agentless/README_orcar.md`, which contain an OrcaLoca-to-Agentless repair/validation/rerank recipe for SWE-bench Lite.

What is not provided as a single turn-key artifact is a fully pinned, end-to-end script for the exact paper table that also covers this repository's Verified50 target, third-party API backends, dataset/cache relocation, retry/resume behavior, and the postprocessing fixes needed for this run. The local patches and scripts in this artifact document those glue steps explicitly.

Patch-selection caveat: the public Agentless regression-test collection path derives regression test directives from SWE-bench `test_patch` metadata through the SWE-bench harness utility. This appears to be part of the public Agentless reproduction recipe, and it is the closest completed match to the paper-style patch-selection step in this artifact. It should be reported as a paper/Agentless-alignment result, not as a strict no-leak selection signal.

Lightweight patch selection in this release means:

1. Agentless repair generates up to 40 candidate patches per instance.
2. Candidate patches are deduplicated.
3. Agentless lightweight rerank selects one final patch per instance for official SWE-bench evaluation.
4. The lightweight selection step does not execute reproduction tests or regression tests for each candidate patch.

The reproduction-test rerank follow-up reuses the same 40 candidate patches per instance, then:

1. Generates up to 5 issue-specific reproduction tests per instance with an LLM.
2. Verifies generated tests on the original code and keeps only tests that reproduce the issue.
3. Runs the verified reproduction tests on each candidate patch.
4. Uses Agentless `rerank.py --reproduction --deduplicate` to select one final patch per instance.
5. Re-runs official SWE-bench evaluation on those final selected patches.

This follow-up improved the conservative resolved rate from 20/50 to 22/50.

The stricter paper-style selection step reuses the same 40 candidate patches, runs public Agentless regression-test validation for candidate patches, then selects with `rerank.py --regression --reproduction --deduplicate`. It also resolves 22/50 on this Verified50 sample: it neither gains nor loses any instance relative to reproduction-test-only rerank.

The final resolved rate is conservative: all 50 sampled instances remain in the denominator. Transient Docker build/export failures were retried; the remaining empty-patch instance is counted as unresolved.

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
  06_regression_reproduction_rerank.sh
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
  all_preds_reproduction_rerank.jsonl
  all_preds_regression_reproduction_rerank.jsonl
  verified50_claude_s40_lightweight_summary.json
  verified50_reproduction_rerank_summary.json
  verified50_regression_reproduction_rerank_summary.json
  verified50_patch_selection_comparison.json
  eval_reports/
docs/
  reproduction_report.md
  implementation_notes.md
```

## Code Provenance

This repository does not vendor the full upstream OrcaLoca or Agentless source trees. Instead, `scripts/00_clone_and_patch.sh` clones pinned upstream checkouts and applies the local compatibility patches.

| Path | Provenance |
| --- | --- |
| `patches/orcaloca_verified_support.patch` | Local reproduction patch against upstream OrcaLoca. |
| `patches/agentless_verified_repair.patch` | Local reproduction patch against upstream Agentless. |
| `overlays/OrcaLoca/` | Full copies of the OrcaLoca files modified by the local patch, included for inspection. |
| `overlays/Agentless/` | Full copies of the Agentless files modified by the local patch, included for inspection. |
| `scripts/` | Local reproduction automation written for this artifact. |
| `configs/` | Local environment templates only; no secrets. |
| `artifacts/verified50/` | Outputs from the reproduction run: sample IDs, loc file, selected patches, metrics, and official SWE-bench reports. |
| `docs/` | Local reproduction notes and implementation explanation. |

Upstream source repositories:

- OrcaLoca: https://github.com/fishmingyu/OrcaLoca
- Agentless: https://github.com/OpenAutoCoder/Agentless
- SWE-bench: https://github.com/swe-bench/SWE-bench

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

The included reproduction-test rerank result was produced as a follow-up using the same 40 repair candidates. Its final selected predictions are in `artifacts/verified50/all_preds_reproduction_rerank.jsonl`, and the official report is in `artifacts/verified50/eval_reports/agentless.orcaloca_verified50_seed20260713_claude_s40_reproduction_rerank.json`.

The paper-aligned regression+reproduction rerank result was then produced from the same 40 repair candidates. Its final selected predictions are in `artifacts/verified50/all_preds_regression_reproduction_rerank.jsonl`, and the official report is in `artifacts/verified50/eval_reports/agentless.orcaloca_verified50_seed20260713_claude_s40_regression_reproduction_rerank.json`.

Run the paper-aligned regression+reproduction rerank after reproduction tests and the 40 repair candidate files are available:

```bash
bash scripts/06_regression_reproduction_rerank.sh
```

Run official SWE-bench evaluation:

```bash
bash scripts/05_run_swebench_eval.sh
```

Summarize results:

```bash
python3 scripts/summarize_results.py \
  --predictions artifacts/verified50/all_preds_regression_reproduction_rerank.jsonl \
  --reports artifacts/verified50/eval_reports/agentless.orcaloca_verified50_seed20260713_claude_s40_regression_reproduction_rerank.json \
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

## Full Intermediate Archive

The complete local intermediate outputs are available as a GitHub Release asset:

- Release: https://github.com/jianminYa/orcaloca-swe-bench-verified/releases/tag/verified50-intermediates-20260721
- Archive: `orcaloca_verified50_intermediates_seed20260713_20260721.tar.zst`
- SHA-256: `03e1290fe488e8fab3fa5ad5bfe947c1b406db421ba0b2694e5953101f07b0a4`
- Localization process archive: `orcaloca_verified50_localization_process_seed20260713_20260721.tar.zst`
- Localization process SHA-256: `16c476d355b928ae10c5da6ad9c7ab3902c10aaad0a7f803194c891859a1e615`
- File tree and inspection guide: [`docs/intermediate_artifacts_guide.md`](docs/intermediate_artifacts_guide.md)

The archive contains:

- OrcaLoca-to-Agentless loc file;
- raw Agentless repair generations for the 40-candidate Claude-compatible run;
- processed and normalized candidate patches;
- reproduction-test and regression-test validation results for candidate patches;
- reproduction-only and regression+reproduction rerank outputs;
- official SWE-bench harness reports;
- top-level execution logs;
- a `MANIFEST.txt` and an archive-local README explaining how to inspect the files.

To inspect it:

```bash
wget https://github.com/jianminYa/orcaloca-swe-bench-verified/releases/download/verified50-intermediates-20260721/orcaloca_verified50_intermediates_seed20260713_20260721.tar.zst
sha256sum orcaloca_verified50_intermediates_seed20260713_20260721.tar.zst
tar --zstd -xf orcaloca_verified50_intermediates_seed20260713_20260721.tar.zst
less orcaloca_verified50_intermediates_seed20260713/artifact_build/verified50_intermediates_README.md
```

The archive excludes Docker layers, Hugging Face cache, cloned repository caches, conda environments, and private API configuration files.

The separate localization process archive preserves the full OrcaLoca search-stage evidence for the 50 sampled instances: `searcher_<instance_id>.json`, `trace_analyzer_<instance_id>.json` when produced, `Orcar.search_agent.log`, `action_history.log`, `search_queue.log`, `Orcar.trace_analysis_agent.log`, and `orcar_total.log`. It is the best artifact for inspecting OrcaLoca's localization behavior rather than only the final repair result.

## Important Caveats

This run is numerically close to the OrcaLoca paper's SWE-bench Lite resolved headline, but it is not a strict same-dataset comparison. The paper reports its main resolved result on SWE-bench Lite 300, while this artifact uses a fixed 50-instance sample from SWE-bench Verified.

The repair stage is closer to the paper-style Agentless setup than earlier OpenAI-compatible `diff_format` experiments because it uses Claude-compatible repair and `str_replace_format`. This release includes the original lightweight rerank result, a reproduction-test rerank follow-up, and the public Agentless regression+reproduction rerank. The final reported result is the regression+reproduction rerank because it is the closest completed match to the paper's patch-selection setup, with the caveat that public Agentless regression validation derives test directives from SWE-bench `test_patch` metadata.
