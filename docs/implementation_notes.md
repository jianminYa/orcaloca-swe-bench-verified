# Implementation Notes

The reproduction required a small set of compatibility patches around dataset handling, OpenAI-compatible APIs, Anthropic-compatible repair, and OrcaLoca-to-Agentless localization adaptation.

## OrcaLoca Changes

- `Orcar/environment/benchmark.py`
  - Adds `ORCAR_CACHE_DIR` support so cached repositories can live outside the default home directory.

- `Orcar/load_cache_dataset.py`
  - Removes the hardcoded SWE-bench Lite JSON schema when reading cached datasets.
  - Builds dataset features dynamically from the cached JSON columns, which allows SWE-bench Verified fields such as `difficulty`.

- `evaluation/process_output.py`
  - Adds `--dataset`, `--filter_instance`, and `--split` arguments.
  - Passes those values into `load_filter_hf_dataset`, so Verified output can be processed without reusing Lite defaults.

## Agentless Changes

- `agentless/util/api_requests.py`
  - Reads OpenAI-compatible base URLs from environment variables.
  - Reads Anthropic-compatible base URLs from `ANTHROPIC_BASE_URL`.
  - Adds configurable retry/timeout behavior for intermittent provider errors.

- `agentless/util/load_dataset_filter.py`
  - Adds explicit target-instance filtering through `AGENTLESS_TARGET_INST_IDS`.
  - Prevents stale Lite target IDs from accidentally filtering a Verified run.

- `agentless/repair/repair.py`
  - De-duplicates `found_files` before applying `top_n`.
  - Restricts edit locations to selected context files to avoid `KeyError`.
  - Writes structured empty repair rows on per-instance failures rather than killing the whole batch.
  - Allows arbitrary model names, including `gpt-5.4-mini` and Claude-compatible provider model names.
  - Requests missing samples one at a time when an OpenAI-compatible backend returns fewer samples than requested.

- `agentless/util/postprocess_data.py`
  - Adds a fallback for exact whole-file SEARCH/REPLACE matching when interval-local replacement fails.
  - This reduces false empty patches when the location interval is too narrow.

- `agentless/test/generate_reproduction_tests.py` and `agentless/test/select_regression_tests.py`
  - Permit `gpt-5.4-mini` as a model choice for optional regression/reproduction-test workflows.

## Why Lightweight Rerank

This release reports the lightweight rerank result because it was sufficient to produce a stable official SWE-bench Verified50 resolved rate after repair alignment. Full Agentless regression/reproduction-test rerank remains the next step for stricter paper-style patch validation, but it is substantially more Docker-intensive.
