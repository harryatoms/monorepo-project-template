from __future__ import annotations

import json
import logging
import traceback as tb
from datetime import datetime, timezone
from typing import Any

from app.logging.context import (
    get_build,
    get_environment,
    get_request_context,
    get_service,
)

_CONTEXT_FIELDS = ("request_id",)

# Modules whose exception messages may contain credential fragments or raw
# upstream payload details (e.g. "Incorrect API key provided: sk-...").
_PROVIDER_MODULE_PREFIXES = ("openai", "httpx", "boto")


def _safe_exc_message(exc_type: type | None, exc_value: BaseException | None) -> str:
    """Return a log-safe exception message string.

    Messages originating from known external provider modules are redacted to
    prevent credential fragments or upstream error payloads from appearing as
    structured log fields.
    """
    if exc_type is None or exc_value is None:
        return ""
    module = getattr(exc_type, "__module__", "") or ""
    if any(module.startswith(p) for p in _PROVIDER_MODULE_PREFIXES):
        return "[redacted provider detail]"
    return str(exc_value)

# ---------------------------------------------------------------------------
# ANSI helpers
# ---------------------------------------------------------------------------

_RESET = "\033[0m"
_DIM   = "\033[2m"
_BOLD  = "\033[1m"

_LEVEL_COLORS: dict[str, str] = {
    "DEBUG":    "\033[34m",     # blue
    "INFO":     "\033[32m",     # green
    "WARNING":  "\033[33m",     # yellow
    "ERROR":    "\033[31m",     # red
    "CRITICAL": "\033[35;1m",   # bold magenta
}
_LEVEL_DISPLAY: dict[str, str] = {
    "DEBUG":    "DEBUG",
    "INFO":     "INFO ",
    "WARNING":  "WARN ",
    "ERROR":    "ERROR",
    "CRITICAL": "CRIT ",
}
_KEY_COLOR  = "\033[36m"   # cyan — attribute keys
_ERR_COLOR  = "\033[31m"   # red  — inline exception summary


class JSONFormatter(logging.Formatter):
    """Formats log records as a single JSON object per line.

    Schema
    ------
    Every record produces exactly these top-level keys::

        timestamp    – ISO-8601 UTC
        level        – DEBUG / INFO / WARNING / ERROR / CRITICAL
        event        – namespaced event string (e.g. ``http.request.received``)
        logger       – dotted logger name
        service      – logical service name (``SERVICE_NAME`` env var,
                       default ``example-api``)
        environment  – deployment environment (``ENVIRONMENT`` env var,
                       default ``local``)

    An ``attributes`` object is included whenever there is anything to report.
    It merges two sources in order, so domain fields can never accidentally
    shadow request-context fields:

    1. Request context (``request_id``, ``method``, ``path``) — propagated
       automatically from :mod:`app.logging.context` without callers passing
       them explicitly.
    2. Per-call keyword arguments supplied to :meth:`~app.logging.StructLogger.emit`.

    An ``error`` object is appended when ``exc_info`` is present.
    """

    def format(self, record: logging.LogRecord) -> str:
        ctx = get_request_context()

        payload: dict[str, Any] = {
            "timestamp": datetime.fromtimestamp(
                record.created, tz=timezone.utc
            ).isoformat(),
            "level": record.levelname,
            "event": getattr(record, "event", record.getMessage()),
            "logger": record.name,
            "service": get_service(),
            "environment": get_environment(),
            "version": get_build(),
        }

        # Build a single flat attributes dict: context fields first so they
        # are always present and cannot be overwritten by domain attributes.
        attributes: dict[str, Any] = {
            field: ctx[field] for field in _CONTEXT_FIELDS if field in ctx
        }
        if record_attrs := getattr(record, "attributes", None):
            attributes.update(record_attrs)
        if attributes:
            payload["attributes"] = attributes

        if record.exc_info:
            exc_type, exc_value, exc_tb = record.exc_info
            payload["error"] = {
                "type": exc_type.__name__ if exc_type else "UnknownError",
                "message": _safe_exc_message(exc_type, exc_value),
                "traceback": tb.format_exception(exc_type, exc_value, exc_tb),
            }

        return json.dumps(payload, default=str)


class DevFormatter(logging.Formatter):
    """Colorised single-line formatter for local development terminals.

    Produces human-readable output while keeping the same logical schema as
    :class:`JSONFormatter` — context fields and domain attributes are surfaced
    as ``key=value`` pairs on one line.  Auto-selected when stdout is a TTY;
    set ``LOG_FORMAT=json`` to force structured output locally.

    Example output::

        10:44:52.450  INFO   http.request.received    request_id=abc-123  method=POST
        10:44:58.263  INFO   api.sample_resource.completed  latency_ms=5812
        10:44:58.264  ERROR  provider.request.failed  error_type=ProviderError
                               └─ ProviderUnavailableError:
    """

    _EVENT_WIDTH = 36  # pad event name to this width for column alignment

    def format(self, record: logging.LogRecord) -> str:
        ctx = get_request_context()

        ts = datetime.fromtimestamp(
            record.created, tz=timezone.utc
        ).strftime("%H:%M:%S.%f")[:-3]
        ts_str = f"{_DIM}{ts}{_RESET}"

        level      = record.levelname
        badge      = _LEVEL_DISPLAY.get(level, level[:5].upper())
        level_str  = f"{_LEVEL_COLORS.get(level, '')}{_BOLD}{badge}{_RESET}"

        event       = getattr(record, "event", record.getMessage())
        event_str   = f"{_BOLD}{event:<{self._EVENT_WIDTH}}{_RESET}"

        svc_str = f"{_DIM}{get_service()}:{get_environment()}{_RESET}"

        # Merge context fields first so they always lead and can't be shadowed.
        attributes: dict[str, Any] = {
            field: ctx[field] for field in _CONTEXT_FIELDS if field in ctx
        }
        if record_attrs := getattr(record, "attributes", None):
            attributes.update(record_attrs)

        attrs_str = "  ".join(
            f"{_KEY_COLOR}{k}{_RESET}={v}" for k, v in attributes.items()
        )

        line = f"{ts_str}  {level_str}  {svc_str}  {event_str}  {attrs_str}".rstrip()

        if record.exc_info:
            exc_type, exc_value, _ = record.exc_info
            err_name = exc_type.__name__ if exc_type else "Error"
            indent   = " " * (len(ts) + 2 + len(badge) + 2 + 2)
            line += (
                f"\n{indent}{_DIM}└─{_RESET} "
                f"{_ERR_COLOR}{err_name}: "
                f"{_safe_exc_message(exc_type, exc_value)}{_RESET}"
            )

        return line
