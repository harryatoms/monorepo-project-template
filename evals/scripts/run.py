from __future__ import annotations

import argparse
import json
import time
from datetime import datetime, timezone
from pathlib import Path

from example_evals import EXAMPLE_SCENARIOS_PATH, EvalResultItem, EvalRunReport, load_scenarios
from example_prompts import load_call, load_prompt

_REPO_ROOT = next(p for p in Path(__file__).resolve().parents if (p / "evals").exists())


def _build_summary(results: list[EvalResultItem]) -> dict:
    total = len(results)
    passed = sum(1 for r in results if r.get("passed"))
    return {"total": total, "passed": passed, "failed": total - passed}


def _write_result(report: EvalRunReport, output: str | None = None) -> Path:
    if output:
        out_path = Path(output).resolve()
    else:
        results_dir = _REPO_ROOT / "evals" / "results" / report["call_name"]
        results_dir.mkdir(parents=True, exist_ok=True)
        timestamp = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H-%M-%S")
        tag = report.get("tag")
        filename = f"{timestamp}-{tag}.json" if tag else f"{timestamp}.json"
        out_path = results_dir / filename
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(report, indent=2), encoding="utf-8")
    return out_path


def _evaluate_scenario(scenario: dict, system_prompt: str) -> EvalResultItem:
    start = time.monotonic()
    prompt = scenario["prompt"]
    expected = scenario.get("expect") or {}
    response = {
        "system_prompt_loaded": bool(system_prompt),
        "prompt": prompt,
        "message": f"Example boilerplate response for: {prompt}",
    }
    text = json.dumps(response).lower()
    failures = [
        f"missing expected text: {needle}"
        for needle in expected.get("contains", [])
        if needle.lower() not in text
    ]
    return {
        "id": scenario["id"],
        "input": prompt,
        "passed": not failures,
        "failures": failures,
        "response": response,
        "expected": expected or None,
        "labels": {"tags": scenario.get("tags", [])},
        "metrics": {"response_length": len(text)},
        "latency_ms": round((time.monotonic() - start) * 1000),
        "error": None,
    }


def run_example(args: argparse.Namespace) -> EvalRunReport:
    call = load_call("example")
    system_prompt = load_prompt(call.prompt)
    scenarios = load_scenarios(Path(args.dataset) if args.dataset else None)
    results = [_evaluate_scenario(s, system_prompt) for s in scenarios]
    return {
        "run_at": datetime.now(timezone.utc).isoformat(),
        "call_name": "example",
        "call_version": call.call_version,
        "model": call.model,
        "dataset": str(args.dataset or EXAMPLE_SCENARIOS_PATH),
        "tag": args.tag,
        "summary": _build_summary(results),
        "results": results,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Run optional boilerplate evals.")
    sub = parser.add_subparsers(dest="call", required=True)
    p = sub.add_parser("example", help="Run the generic example smoke eval")
    p.add_argument("--dataset")
    p.add_argument("--output")
    p.add_argument("--tag")
    args = parser.parse_args()

    report = run_example(args)
    out = _write_result(report, args.output)
    summary = report["summary"]
    print(f"wrote {out}")
    print(f"summary passed={summary['passed']}/{summary['total']} failed={summary['failed']}")
    return 0 if summary["failed"] == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
