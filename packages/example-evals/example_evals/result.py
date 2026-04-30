from __future__ import annotations

from typing import TypedDict


class EvalResultItem(TypedDict, total=False):
    id: str
    input: str
    passed: bool
    failures: list[str]
    response: dict
    expected: dict | None
    labels: dict
    metrics: dict | None
    latency_ms: int | None
    error: str | None


class EvalRunReport(TypedDict, total=False):
    run_at: str
    call_name: str
    call_version: str
    model: str
    dataset: str | None
    tag: str | None
    summary: dict
    results: list[EvalResultItem]
