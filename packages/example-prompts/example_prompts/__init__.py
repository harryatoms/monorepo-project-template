"""Versioned prompt templates and LLM call configs for the boilerplate."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Any

import yaml
from jinja2 import FileSystemLoader
from jinja2.sandbox import SandboxedEnvironment

_TEMPLATES_DIR = Path(__file__).parent / "templates"
_CALLS_DIR = Path(__file__).parent / "calls"

_env = SandboxedEnvironment(loader=FileSystemLoader(str(_TEMPLATES_DIR)))


def load_prompt(name: str) -> str:
    """Load a prompt template by relative name without the file extension."""
    return _env.get_template(f"{name}.txt").render().strip()


@dataclass(frozen=True)
class CallConfig:
    call_version: str
    prompt: str
    model: str
    max_completion_tokens: int
    reasoning_effort: str | None


def load_call(name: str) -> CallConfig:
    """Load a named LLM call config."""
    path = _CALLS_DIR / f"{name}.yaml"
    if not path.exists():
        raise FileNotFoundError(f"No call config found for '{name}'. Expected: {path}")
    raw: dict[str, Any] = yaml.safe_load(path.read_text(encoding="utf-8"))
    return CallConfig(
        call_version=str(raw["call_version"]),
        prompt=raw["prompt"],
        model=raw["model"],
        max_completion_tokens=int(raw["max_completion_tokens"]),
        reasoning_effort=raw.get("reasoning_effort") or None,
    )
