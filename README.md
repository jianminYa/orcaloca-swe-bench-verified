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

Primary completed result in this artifact: reproduction-test rerank, `22/50 = 44.00%`.

The lightweight rerank result is retained as an ablation, not the final recommended number.

| Metric | Result |
| --- | ---: |
| File Match | 38/50 = 76.00% |
| Function Match | 29/50 = 58.00% |
| Resolved Rate, reproduction-test rerank | 22/50 = 44.00% |
| Resolved Rate, lightweight rerank | 20/50 = 40.00% |
| Official reports, reproduction-test rerank | 49/50 |
| Empty patch | 1/50 |
| Docker infra errors after retry | 0 |

The one missing official report is the empty-patch instance `sphinx-doc__sphinx-9258`. It is counted as unresolved in the conservative resolved-rate denominator.

## Comparison to the OrcaLoca Paper

The OrcaLoca paper reports its headline result on SWE-bench Lite 300 with Claude 3.5 Sonnet and Agentless-1.5 repair integration:

| Metric | OrcaLoca paper on SWE-bench Lite 300 | This artifact on SWE-bench Verified50 |
| --- | ---: | ---: |
| File Match | 250/300 = 83.33% | 38/50 = 76.00% |
| Function Match | 196/300 = 65.33% | 29/50 = 58.00% |
| Resolved Rate | 123/300 = 41.00% | 22/50 = 44.00% with reproduction-test rerank; 20/50 = 40.00% with lightweight rerank |

This is not a same-dataset reproduction: the paper uses SWE-bench Lite, while this artifact uses a fixed 50-instance sample from SWE-bench Verified. The resolved-rate magnitude is close, but the localization metrics are lower on this Verified50 sample. The result should therefore be interpreted as a transfer reproduction of the OrcaLoca + Agentless-style pipeline, not as a replacement for the paper's SWE-bench Lite 300 table.

Reference: OrcaLoca paper, Table 1 and Section 4.2.1, https://arxiv.org/abs/2502.00350.

## Configuration and Paper Alignment

The table below separates the pipeline stages and marks whether this Verified50 artifact follows the OrcaLoca paper's SWE-bench Lite setup.

| Stage | OrcaLoca paper setup | This artifact | Alignment |
| --- | --- | --- | --- |
| Dataset | SWE-bench Lite 300, `test` split | SWE-bench Verified, fixed repo-stratified 50-instance sample, `test` split | Not aligned by design. The reproduction target was moved to Verified50. |
| Localization method | OrcaLoca search/localization | OrcaLoca search/localization | Aligned in method. |
| Localization model | Claude 3.5 Sonnet in the paper's reported Lite table | `gpt-5.4-mini` through an OpenAI-compatible backend | Not model-aligned. |
| Loc-to-repair bridge | OrcaLoca localization integrated with Agentless-1.5 patch generation | OrcaLoca output converted to Agentless `loc_file` format | Partially aligned. This artifact includes compatibility fixes for Verified and Agentless input formatting. |
| Repair framework | Agentless-1.5 repair integration | Agentless repair | Aligned in framework family. |
| Repair model | Claude 3.5 Sonnet in the paper's reported Lite table | `claude-haiku-4-5-20251001` through an Anthropic-compatible backend | Not model-aligned, but closer than the earlier OpenAI-compatible `diff_format` repair attempt. |
| Repair sampling | Agentless-style multi-candidate repair; the paper reports the final OrcaLoca + Agentless-1.5 result | `max_samples=40`, `top_n=3`, `context_window=10`, `--loc_interval`, `--cot`, `--str_replace_format` | Partially aligned. `max_samples=40` and search/replace-style repair are used, but the exact paper release pipeline is not fully specified in the OrcaLoca paper. |
| Patch generation format | Agentless-style repair format; exact prompt/parser details are not fully specified in the OrcaLoca paper | `--str_replace_format` | Best-effort alignment with Agentless-style repair. |
| Patch selection | Agentless-1.5 uses both regression and reproduction test results to select among the 40 candidates | Two completed results are included: lightweight Agentless rerank with `--deduplicate`, and a reproduction-test rerank follow-up with `--reproduction --deduplicate` | Partially aligned. The reproduction-test rerank adds test-based candidate validation, but the full paper-style `--regression --reproduction` rerank has not been reported as the primary result here. |
| Official evaluation | SWE-bench official evaluation on Lite | `swebench.harness.run_evaluation` on Verified50 | Aligned in evaluator, not in dataset. |

The OrcaLoca paper does describe the key resolved-stage setup: OrcaLoca output is converted to Agentless format; Agentless Repair, Patch Validation, and Patch Selection are integrated; Claude-3.5-Sonnet-20241022 is used; 40 patches are generated with `str_replace_format`; both regression and reproduction tests are used for patch validation and final candidate selection. The upstream OrcaLoca repository also points users from `evaluation/process_output.py` to `evaluation/orcar_agentless/README.md` and `third_party/Agentless/README_orcar.md`, which contain an OrcaLoca-to-Agentless repair/validation/rerank recipe for SWE-bench Lite.

What is not provided as a single turn-key artifact is a fully pinned, end-to-end script for the exact paper table that also covers this repository's Verified50 target, third-party API backends, dataset/cache relocation, retry/resume behavior, and the postprocessing fixes needed for this run. The local patches and scripts in this artifact document those glue steps explicitly.

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

This follow-up improved the conservative resolved rate from 20/50 to 22/50. It is the strongest completed result currently included in this artifact.

The stricter paper-style next step is to run the public Agentless `--regression --reproduction` rerank using the same 40 candidates. One caveat is that the public Agentless regression-test collection path runs test directives derived from SWE-bench `test_patch` metadata through the SWE-bench harness utility. This appears to be part of the public Agentless reproduction recipe, but it should be labeled clearly as a paper/Agentless-alignment experiment rather than presented as a no-leak selection signal.

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
  verified50_claude_s40_lightweight_summary.json
  verified50_reproduction_rerank_summary.json
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

Run official SWE-bench evaluation:

```bash
bash scripts/05_run_swebench_eval.sh
```

Summarize results:

```bash
python3 scripts/summarize_results.py \
  --predictions artifacts/verified50/all_preds_reproduction_rerank.jsonl \
  --reports artifacts/verified50/eval_reports/agentless.orcaloca_verified50_seed20260713_claude_s40_reproduction_rerank.json \
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

The repair stage is closer to the paper-style Agentless setup than earlier OpenAI-compatible `diff_format` experiments because it uses Claude-compatible repair and `str_replace_format`. This release includes both the original lightweight rerank result and a reproduction-test rerank follow-up. It still does not report the public Agentless regression-test rerank as the primary result because that path derives test directives from SWE-bench `test_patch` metadata.
