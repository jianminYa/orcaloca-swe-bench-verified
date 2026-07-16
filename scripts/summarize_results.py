#!/usr/bin/env python3
import argparse
import json
from pathlib import Path


def load_json(path: Path):
    with path.open() as f:
        return json.load(f)


def iter_report_files(root: Path):
    if root.is_file():
        yield root
        return
    yield from sorted(root.rglob("*.json"))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--predictions", required=True, type=Path)
    parser.add_argument("--reports", required=True, type=Path)
    parser.add_argument("--instance-ids", required=True, type=Path)
    args = parser.parse_args()

    ids = [line.strip() for line in args.instance_ids.read_text().splitlines() if line.strip()]

    empty = []
    for line in args.predictions.read_text().splitlines():
        if not line.strip():
            continue
        row = json.loads(line)
        if not (row.get("model_patch") or "").strip():
            empty.append(row["instance_id"])

    reports = {}
    summary_resolved = set()
    summary_unresolved = set()
    summary_empty = set()
    for report_path in iter_report_files(args.reports):
        data = load_json(report_path)
        if not isinstance(data, dict):
            continue
        if "resolved_ids" in data or "unresolved_ids" in data:
            summary_resolved.update(i for i in data.get("resolved_ids", []) if i in ids)
            summary_unresolved.update(i for i in data.get("unresolved_ids", []) if i in ids)
            summary_empty.update(i for i in data.get("empty_patch_ids", []) if i in ids)
            continue
        for instance_id, result in data.items():
            if instance_id in ids and isinstance(result, dict) and "resolved" in result:
                reports[instance_id] = result

    resolved = set(i for i, result in reports.items() if result.get("resolved") is True)
    unresolved = set(i for i, result in reports.items() if result.get("resolved") is False)
    resolved.update(summary_resolved)
    unresolved.update(summary_unresolved - resolved)
    empty = sorted(set(empty).union(summary_empty))
    reported = resolved.union(unresolved)
    missing = [i for i in ids if i not in reported and i not in empty]

    summary = {
        "total_instances": len(ids),
        "reports_count": len(reported),
        "resolved_count": len(resolved),
        "unresolved_count": len(unresolved),
        "empty_patch_count": len(empty),
        "missing_report_count": len(missing),
        "resolved_rate_conservative": len(resolved) / len(ids) if ids else None,
        "resolved": sorted(resolved),
        "unresolved": sorted(unresolved),
        "empty_patch": empty,
        "missing_report": missing,
    }

    print(json.dumps(summary, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
