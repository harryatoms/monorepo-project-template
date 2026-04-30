from __future__ import annotations

import logging
import os
import sys
from typing import Any

from app.logging.formatter import DevFormatter, JSONFormatter


def _is_dev_mode() -> bool:
    """Return True when log output should be human-readable rather than JSON.

    Resolution order:
    - ``LOG_FORMAT=json`` → always structured JSON (CI, log shippers, Docker)
    - ``LOG_FORMAT=dev``  → always colourised dev output
    - unset / ``auto``   → colourised when stdout is an interactive TTY
    """
    override = os.environ.get("LOG_FORMAT", "auto").lower()
    if override == "json":
        return False
    if override == "dev":
        return True
    return sys.stdout.isatty()


def _make_formatter() -> logging.Formatter:
    return DevFormatter() if _is_dev_mode() else JSONFormatter()


def _formatter_class_name() -> str:
    """String reference used in dictConfig so the dict stays serialisable."""
    return (
        "app.logging.formatter.DevFormatter"
        if _is_dev_mode()
        else "app.logging.formatter.JSONFormatter"
    )


def build_uvicorn_log_config(level: str = "INFO") -> dict[str, Any]:
    """Return a :func:`logging.config.dictConfig`-compatible dict for uvicorn.

    Routes uvicorn's own loggers (startup, shutdown, errors) through the same
    formatter chosen for the application so all output is uniform.
    ``uvicorn.access`` is silenced because
    :class:`~app.logging.middleware.RequestContextMiddleware` already emits
    richer ``http.request.received`` / ``http.request.completed`` events.

    Pass the returned dict as ``log_config`` to :func:`uvicorn.run`.
    """
    return {
        "version": 1,
        "disable_existing_loggers": False,
        "formatters": {
            "default": {"()": _formatter_class_name()},
        },
        "handlers": {
            "stdout": {
                "class": "logging.StreamHandler",
                "stream": "ext://sys.stdout",
                "formatter": "default",
            },
        },
        "loggers": {
            # Startup / shutdown / error messages from uvicorn itself.
            "uvicorn": {
                "handlers": ["stdout"],
                "level": level,
                "propagate": False,
            },
            # uvicorn.error propagates to uvicorn — no extra handler needed.
            "uvicorn.error": {
                "level": level,
                "propagate": True,
            },
            # Suppressed: RequestContextMiddleware emits
            # http.request.received/completed.
            "uvicorn.access": {
                "handlers": [],
                "level": "WARNING",
                "propagate": False,
            },
        },
    }


def configure_logging(level: int = logging.INFO) -> None:
    """Configure the root logger with the environment-appropriate formatter.

    Selects :class:`~app.logging.formatter.DevFormatter` when running in an
    interactive terminal and :class:`~app.logging.formatter.JSONFormatter`
    otherwise.  Override with ``LOG_FORMAT=json|dev``.

    Call this exactly once, before the FastAPI app is constructed.
    """
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(_make_formatter())

    root = logging.getLogger()
    root.setLevel(level)
    root.handlers = []
    root.addHandler(handler)

    # Reduce noise from verbose third-party libraries.
    for noisy in ("httpx", "openai._base_client", "botocore.credentials"):
        logging.getLogger(noisy).setLevel(logging.WARNING)
