from __future__ import annotations

import os
from contextvars import ContextVar, Token
from typing import Any

_ctx: ContextVar[dict[str, Any]] = ContextVar("request_context", default={})

_build: str | None = None
_service: str | None = None
_environment: str | None = None


def get_build() -> str:
    global _build
    if _build is None:
        _build = os.environ.get("VERSION") or "local"
    return _build


def get_service() -> str:
    global _service
    if _service is None:
        _service = os.environ.get("SERVICE_NAME") or "example-api"
    return _service


def get_environment() -> str:
    global _environment
    if _environment is None:
        _environment = os.environ.get("ENVIRONMENT") or "local"
    return _environment


def set_request_context(**fields: Any) -> Token[dict[str, Any]]:
    return _ctx.set(fields)


def reset_request_context(token: Token[dict[str, Any]]) -> None:
    _ctx.reset(token)


def get_request_context() -> dict[str, Any]:
    return _ctx.get()
