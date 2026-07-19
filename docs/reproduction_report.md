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
5. Run a reproduction-test rerank follow-up using the same 40 repair candidates.
6. Run public Agentless regression+reproduction rerank using the same 40 repair candidates.
7. Evaluate final selected patches with the official SWE-bench harness.
8. Retry transient Docker build/export failures with `max_workers=1`.

## Metrics

The primary completed result is the regression+reproduction rerank result because it is the closest completed match to the paper's Agentless patch-selection setup. The reproduction-test-only and lightweight rerank results are retained as ablations.

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

This does not mean 49 instances passed. It means the official SWE-bench harness evaluated 49 non-empty patches. The empty patch instance is `sphinx-doc__sphinx-9258`, and it is counted as unresolved.

## Interpretation

The resolved result is close in magnitude to the OrcaLoca paper's SWE-bench Lite headline resolved rate, but it is not a direct same-dataset comparison. This run uses SWE-bench Verified50, while the paper headline uses SWE-bench Lite300.

The main improvement over earlier low-result runs came from aligning the repair stage:

- Claude-compatible repair model;
- `str_replace_format`;
- `max_samples=40`;
- fewer non-model empty patches after dataset-filter and loc-file adaptation fixes.

Lightweight rerank selected final patches from the 40 candidates and resolved 20/50. The reproduction-test rerank follow-up reused the same 40 candidates, generated and verified issue-specific reproduction tests, ran them on candidate patches, then selected final patches with `--reproduction --deduplicate`; it resolved 22/50. The two additional resolved instances were `django__django-12708` and `pydata__xarray-3095`, with no instance lost relative to lightweight rerank.

The public Agentless regression+reproduction rerank then reused the same 40 candidates and selected final patches with `--regression --reproduction --deduplicate`. It also resolved 22/50, with no gain and no loss relative to reproduction-test-only rerank.

The regression+reproduction result should still be read with one caveat: the public Agentless regression-test rerank path derives regression test directives from SWE-bench `test_patch` metadata through the harness utility. That makes it the closest paper-alignment experiment in this artifact, but not a no-leak selection signal.
