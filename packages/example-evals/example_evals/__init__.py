"""Example eval datasets and loaders for the boilerplate."""

from __future__ import annotations

import json
from pathlib import Path

from example_evals.result import EvalResultItem, EvalRunReport

_DATASETS_DIR = Path(__file__).parent / "datasets"
EXAMPLE_SCENARIOS_PATH = _DATASETS_DIR / "example" / "scenarios.jsonl"


def load_scenarios(path: Path | None = None) -> list[dict]:
    target = path if path is not None else EXAMPLE_SCENARIOS_PATH
    return [
        json.loads(line)
        for line in target.read_text(encoding="utf-8").splitlines()
        if line.strip()
    ]


__all__ = [
    "EXAMPLE_SCENARIOS_PATH",
    "EvalResultItem",
    "EvalRunReport",
    "load_scenarios",
]
