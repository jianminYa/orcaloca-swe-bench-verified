# Verified50 OrcaLoca/Agentless Claude s40 Lightweight Summary

- Dataset: `princeton-nlp/SWE-bench_Verified`, split `test`
- Sample: fixed seed `20260713`, repo-stratified 50 instances
- Localization: OrcaLoca with `gpt-5.4-mini` through an OpenAI-compatible API
- Repair: Agentless with `claude-haiku-4-5-20251001` through an Anthropic-compatible API
- Repair settings: `max_samples=40`, `top_n=3`, `context_window=10`, `--loc_interval --cot --str_replace_format`
- Selection: Agentless lightweight rerank with `--deduplicate`; regression/reproduction-test rerank was not run for this release

## Result

- File Match: 38/50 = 76.00%
- Function Match: 29/50 = 58.00%
- Completed official SWE-bench reports: 49/50
- Resolved: 20
- Unresolved: 29
- Empty patch: 1 (sphinx-doc__sphinx-9258)
- Docker infrastructure errors after retry: 0
- Conservative resolved rate over all 50 sampled instances: 20/50 = 40.00%
- Resolved rate over completed official reports only: 20/49 = 40.82%

## Notes

The main evaluation initially had Docker build/export errors for two instances. Both were retried with `max_workers=1`; `sympy__sympy-15599` and `matplotlib__matplotlib-25122` completed as unresolved. The only missing official report is the expected empty-patch instance `sphinx-doc__sphinx-9258`.

## Included Files

- `verified50_seed20260713_instance_ids.txt`: final 50 instance IDs
- `verified50_seed20260713_metadata.json`: sampling metadata
- `loc_orcar_outputs.jsonl`: Agentless localization file prepared from OrcaLoca outputs
- `all_preds_lightweight.jsonl`: final selected patches used for official evaluation
- `eval_reports/*.json`: official SWE-bench harness report files
- `sample_outputs/patch_only_samples.jsonl`: compact patch-only examples for quick inspection
