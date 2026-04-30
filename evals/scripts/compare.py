from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


def _load(path: str) -> dict:
    p = Path(path)
    if not p.exists():
        print(f"error: file not found: {path}", file=sys.stderr)
        sys.exit(1)
    return json.loads(p.read_text(encoding="utf-8"))


def _index(run: dict) -> dict[str, dict]:
    return {item["id"]: item for item in run.get("results", [])}


def main() -> int:
    parser = argparse.ArgumentParser(description="Compare two boilerplate eval reports.")
    parser.add_argument("baseline")
    parser.add_argument("candidate")
    parser.add_argument("--verbose", action="store_true")
    args = parser.parse_args()

    baseline = _load(args.baseline)
    candidate = _load(args.candidate)
    base_idx = _index(baseline)
    cand_idx = _index(candidate)

    print("Summary")
    print(f"  baseline:  {baseline.get('summary', {})}")
    print(f"  candidate: {candidate.get('summary', {})}")

    new_failures = []
    for item_id, candidate_item in sorted(cand_idx.items()):
        baseline_item = base_idx.get(item_id)
        failed_now = not candidate_item.get("passed")
        failed_before = baseline_item is not None and not baseline_item.get("passed")
        if failed_now and not failed_before:
            new_failures.append(item_id)

    if args.verbose:
        for item_id in sorted(set(base_idx) | set(cand_idx)):
            print(f"\n{item_id}")
            print(f"  baseline:  {base_idx.get(item_id)}")
            print(f"  candidate: {cand_idx.get(item_id)}")

    if new_failures:
        print("new failures:")
        for item_id in new_failures:
            print(f"  - {item_id}")
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
