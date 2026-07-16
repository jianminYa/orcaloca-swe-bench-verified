# Reproduction Report

## Scope

This artifact evaluates OrcaLoca localization plus Agentless repair on a fixed 50-instance sample from SWE-bench Verified.

It is intended to answer whether the pipeline can be transferred from SWE-bench Lite to SWE-bench Verified while keeping the key Agentless repair configuration close to the paper-style setup.

## Dataset and Sampling

- Dataset: `princeton-nlp/SWE-bench_Verified`
- Split: `test`
- Dataset size: 500
- Sample size: 50
- Seed: `20260713`
- Sampling: proportional stratified random sample by repository
- Replacement: `django__django-7530` was replaced by `django__django-16595` after repeated search-stage environment failure

The final instance list is in `artifacts/verified50/verified50_seed20260713_instance_ids.txt`.

## Pipeline

1. Run OrcaLoca search/localization on the fixed 50 instances.
2. Convert OrcaLoca outputs to Agentless `loc_file` format.
3. Run Agentless repair with Claude-compatible backend and `max_samples=40`.
4. Run Agentless lightweight rerank with deduplication.
5. Evaluate final selected patches with the official SWE-bench harness.
6. Retry transient Docker build/export failures with `max_workers=1`.

## Metrics

| Metric | Result |
| --- | ---: |
| File Match | 38/50 = 76.00% |
| Function Match | 29/50 = 58.00% |
| Resolved Rate | 20/50 = 40.00% |
| Official reports | 49/50 |
| Empty patch | 1/50 |
| Docker infra errors after retry | 0 |

The empty patch instance is `sphinx-doc__sphinx-9258`.

## Interpretation

The resolved result is close in magnitude to the OrcaLoca paper's SWE-bench Lite headline resolved rate, but it is not a direct same-dataset comparison. This run uses SWE-bench Verified50, while the paper headline uses SWE-bench Lite300.

The main improvement over earlier low-result runs came from aligning the repair stage:

- Claude-compatible repair model;
- `str_replace_format`;
- `max_samples=40`;
- fewer non-model empty patches after dataset-filter and loc-file adaptation fixes.

Lightweight rerank selected final patches from the 40 candidates. Full regression/reproduction-test rerank may still change the resolved rate, but that step was not included in this release.
