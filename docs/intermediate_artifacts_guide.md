# Intermediate Artifacts Guide

This document explains the full intermediate artifact archive for the Verified50 reproduction. It is meant for inspecting what was run, which model produced which outputs, and which local files preserve the intermediate state.

Archive release:

- GitHub Release: https://github.com/jianminYa/orcaloca-swe-bench-verified/releases/tag/verified50-intermediates-20260721
- Archive: `orcaloca_verified50_intermediates_seed20260713_20260721.tar.zst`
- SHA-256: `03e1290fe488e8fab3fa5ad5bfe947c1b406db421ba0b2694e5953101f07b0a4`

Inspect commands:

```bash
wget https://github.com/jianminYa/orcaloca-swe-bench-verified/releases/download/verified50-intermediates-20260721/orcaloca_verified50_intermediates_seed20260713_20260721.tar.zst
sha256sum orcaloca_verified50_intermediates_seed20260713_20260721.tar.zst
tar --zstd -xf orcaloca_verified50_intermediates_seed20260713_20260721.tar.zst
cd orcaloca_verified50_intermediates_seed20260713
less artifact_build/verified50_intermediates_README.md
less artifact_build/MANIFEST.txt
```

## File Tree

```text
orcaloca_verified50_intermediates_seed20260713/
  artifact_build/
    verified50_intermediates_README.md
    MANIFEST.txt

  metadata/
    verified50_seed20260713_instance_ids.txt
    verified50_seed20260713_instance_ids_space.txt
    verified50_seed20260713_regex.txt
    verified50_seed20260713_metadata.json
    *.before_replacement_django7530

  agentless_outputs/
    results/
      swe-bench-lite/
        edit_location_individual/
          loc_orcar_outputs.jsonl

    repair_verified50_seed20260713_claude_s40_strreplace/
      output.jsonl
      used_locs.jsonl
      output_0_processed.jsonl
      output_0_normalized.jsonl
      output_0_reproduction_test_results.jsonl
      output_0_regression_test_results.jsonl
      ...
      output_39_processed.jsonl
      output_39_normalized.jsonl
      output_39_reproduction_test_results.jsonl
      output_39_regression_test_results.jsonl
      repair_logs/
        <instance_id>.log

  reproduction_test_rerank/
    reproduction_tests/
    reproduction_test_results/
    rerank_outputs/
    harness_reports/

  paper_aligned_rerank/
    regression_selection/
    regression_test_results/
    rerank_outputs/
    strategy_comparison/

  harness_runtime/
    lightweight/
    reproduction_rerank/
    regression_reproduction_rerank/

  run_verified50*.log
  verified50*.json
```

Some directory names still contain `swe-bench-lite` because the public Agentless helper path hardcodes that output subdirectory name. The actual dataset used in this run is `princeton-nlp/SWE-bench_Verified`, split `test`; the fixed instance list is in `metadata/verified50_seed20260713_instance_ids.txt`.

## What Each Part Contains

`artifact_build/`

- `verified50_intermediates_README.md`: archive-local short guide.
- `MANIFEST.txt`: complete file list and file sizes. Use this first when checking whether a specific output exists.

`metadata/`

- `verified50_seed20260713_instance_ids.txt`: final 50 sampled instance IDs, one per line.
- `verified50_seed20260713_metadata.json`: sample seed, repo-stratified sampling metadata, repo distribution, and replacement record.
- `*.before_replacement_django7530`: retained audit files from the first sample list before replacing one repeatedly failing search-stage instance.

`agentless_outputs/results/.../loc_orcar_outputs.jsonl`

- This is the OrcaLoca localization output converted into Agentless `loc_file` format.
- It is the bridge from OrcaLoca search/localization to Agentless repair.
- Inspect it to answer: which files/functions/line intervals did OrcaLoca send to repair for each issue?

`agentless_outputs/repair_verified50_seed20260713_claude_s40_strreplace/output.jsonl`

- Raw Agentless repair generations.
- The repair model for this run was `claude-haiku-4-5-20251001` through an Anthropic-compatible backend.
- The configuration used `max_samples=40`, `top_n=3`, `context_window=10`, `--loc_interval`, `--cot`, and `--str_replace_format`.
- Inspect it to answer: what did the repair model generate before patch postprocessing?

`output_{0..39}_processed.jsonl`

- Processed candidate patches after Agentless postprocessing.
- There is one file per candidate index because `max_samples=40`: `output_0_processed.jsonl` stores candidate 0 for all 50 issues, `output_1_processed.jsonl` stores candidate 1, and so on.
- Inspect these files to answer: which actual git diff was produced for a candidate?

`output_{0..39}_normalized.jsonl`

- Normalized candidate patches used by rerank scripts.
- These files make candidate comparison and deduplication more stable.

`output_{0..39}_reproduction_test_results.jsonl`

- Results from running issue-specific reproduction tests against each candidate patch.
- These tests were generated and validated in the reproduction-test rerank workflow.
- Inspect them to answer: did a candidate pass the generated issue reproduction test?

`output_{0..39}_regression_test_results.jsonl`

- Results from running the public Agentless regression validation workflow against each candidate patch.
- This is used by the closest paper-aligned rerank result in this artifact.
- Caveat: the public Agentless regression-test collection path derives regression test directives from SWE-bench `test_patch` metadata through the SWE-bench harness utility. We therefore report it as a paper/Agentless-alignment result rather than as a strict no-leak selection signal.

`repair_logs/<instance_id>.log`

- Per-instance Agentless repair logs.
- Useful for diagnosing empty patches, backend errors, malformed model output, and postprocessing behavior.

`reproduction_test_rerank/`

- Stores the generated reproduction tests, their validation outputs, reproduction-test-only rerank output, and official SWE-bench harness reports for that ablation.
- This workflow improved the resolved result from `20/50` to `22/50`.

`paper_aligned_rerank/`

- Stores the regression-test selection outputs, candidate regression validation outputs, final `--regression --reproduction --deduplicate` rerank output, and strategy comparison files.
- This is the closest completed public-workflow alignment to the OrcaLoca paper's patch-selection description in this Verified50 artifact.
- It also resolved `22/50`.

`harness_runtime/`

- Official SWE-bench harness runtime outputs.
- Inspect these files to answer: which final patches were counted as resolved or unresolved by `swebench.harness.run_evaluation`?

`run_verified50*.log`

- Top-level execution logs for localization, repair, rerank, and evaluation commands.
- Use these for command-line provenance and failure diagnosis.

`verified50*.json`

- Compact summaries used by the repository README and report.
- These are the fastest files to inspect for final counts.

## LLM Configuration

The completed Verified50 result used different models at different stages:

| Stage | Model/backend | Notes |
| --- | --- | --- |
| OrcaLoca search/localization | `gpt-5.4-mini`, OpenAI-compatible backend | Finds likely files/functions/locations for each issue. |
| Agentless repair patch generation | `claude-haiku-4-5-20251001`, Anthropic-compatible backend | Chosen because public Agentless `str_replace_format` is implemented for the Anthropic backend. This better matches the paper-style repair format than the earlier OpenAI-compatible `diff_format` attempt. |
| Reproduction/regression test generation or selection where LLM is used | `gpt-5.4-mini`, OpenAI-compatible backend | Used for auxiliary test-selection/test-generation workflows where applicable. |
| Official SWE-bench evaluation | No LLM | Runs candidate patches inside Docker/SWE-bench harness. |

The primary repair settings were:

```text
max_samples=40
top_n=3
context_window=10
--loc_interval
--cot
--str_replace_format
```

## About Memory and Local Intermediate State

OrcaLoca does not use a persistent cross-instance memory database in this reproduction. It is an inference-time software issue localization agent.

There are three different things that can be confused as "memory":

1. Runtime chat/search context.
   OrcaLoca uses per-instance `ChatMemoryBuffer` objects and an `action_history` while searching a single issue. The prompt contains previous `<Search Result>` and new `<New Info>` blocks so the model can refine the bug location. This state is temporary during the run.

2. Saved localization outputs.
   The useful retained state from OrcaLoca is the per-instance search/localization output, especially `loc_orcar_outputs.jsonl`. This records the files/functions/intervals passed to Agentless repair.

3. Reproducibility caches.
   Local repository checkouts, Hugging Face datasets, and Docker/SWE-bench environments may be cached on disk during execution. These are cache/runtime data, not model memory. They are excluded from the public archive because they are large and reproducible.

So if asked whether "memory" was kept locally, the accurate answer is:

- No separate long-term memory module or vector memory was used or published.
- Yes, the run preserves the important intermediate artifacts: sampled instance IDs, OrcaLoca localization outputs, Agentless loc files, raw repair generations, 40 candidate patches per issue, reproduction/regression validation results, rerank outputs, official SWE-bench harness reports, and execution logs.
- The per-issue prompt/search history exists in runtime logs and JSON outputs where recorded, not as a standalone memory database.

## Suggested Advisor Reply

```text
师兄，实验设置我整理在 GitHub README 的 Result 和 Configuration and Paper Alignment 两个表里。简要说：

1. 数据集是 SWE-bench Verified 的 test split，用固定 seed=20260713 按 repo 分层随机抽取 50 个样例。
2. 流程是 OrcaLoca search/localization -> 转成 Agentless loc_file -> Agentless repair -> 每个 issue 生成 40 个候选 patch -> regression+reproduction rerank 选最终 patch -> SWE-bench official harness 评估。
3. LLM 设置是：定位/search 阶段用 gpt-5.4-mini；repair 生成 patch 阶段用 claude-haiku-4-5-20251001，因为公开 Agentless 的 str_replace_format 绑定 Anthropic backend，这样比之前 OpenAI-compatible diff_format 更接近论文配置；reproduction/regression test 生成或选择里需要 LLM 的地方用 gpt-5.4-mini；最终 official harness evaluation 不调用 LLM，只跑 Docker 测试。
4. 关键 repair 参数是 max_samples=40, top_n=3, context_window=10, loc_interval, cot, str_replace_format。
5. 当前 Verified50 结果是 file match 38/50, function match 29/50, resolved 22/50=44%。

中间结果方面，完整中间产物已经放到 GitHub Release。里面保留了 sample ids、OrcaLoca localization 输出、Agentless loc_file、raw repair generations、40 个候选 patch、reproduction/regression test 结果、rerank 输出、official harness report 和日志。

关于 memory：OrcaLoca 不是训练任务，也没有跨样本的长期 memory 或 memory database。它在单个 issue 搜索过程中有临时的 chat/search context 和 action_history，用 issue statement、repo search 结果和历史 Search Result/New Info 引导模型定位 bug。我们保留的是这些推理过程产生的 localization JSON/log 和后续 repair/rerank/evaluation 中间文件，不是单独的 memory 模块。
```
