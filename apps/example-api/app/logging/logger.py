from __future__ import annotations

import logging
from typing import Any


class StructLogger:
    """Thin wrapper around :class:`logging.Logger` that adds structured event emission.

    Standard logging methods (``info``, ``warning``, ``exception``, etc.) are
    delegated to the underlying logger so callers can mix plain and structured
    calls freely.  The :meth:`emit` method is the preferred entry-point for
    named domain and observability events.
    """

    __slots__ = ("_log",)

    def __init__(self, name: str) -> None:
        self._log = logging.getLogger(name)

    def emit(
        self,
        event: str,
        *,
        level: str = "info",
        exc_info: bool = False,
        exc: BaseException | None = None,
        **attributes: Any,
    ) -> None:
        """Emit a named structured event.

        Args:
            event:      Short snake_case event name,
                        e.g. ``"sample_resource_completed"``.
            level:      stdlib log level name (``"debug"``, ``"info"``, ``"warning"``,
                        ``"error"``, ``"critical"``).
            exc_info:   Capture the current exception from ``sys.exc_info()``
                        (use inside ``except`` blocks).
            exc:        Explicit exception to attach (use when not inside an
                        ``except`` block, e.g. FastAPI exception handlers).
            **attributes: Arbitrary key-value pairs recorded under ``attributes``
                        in the JSON payload.
        """
        extra = {"event": event, "attributes": attributes or None}
        resolved: Any
        if exc is not None:
            resolved = (type(exc), exc, exc.__traceback__)
        else:
            resolved = exc_info
        getattr(self._log, level)(event, exc_info=resolved, extra=extra)

    # --- stdlib pass-throughs ---

    def debug(self, msg: str, *args: Any, **kwargs: Any) -> None:
        self._log.debug(msg, *args, **kwargs)

    def info(self, msg: str, *args: Any, **kwargs: Any) -> None:
        self._log.info(msg, *args, **kwargs)

    def warning(self, msg: str, *args: Any, **kwargs: Any) -> None:
        self._log.warning(msg, *args, **kwargs)

    def error(self, msg: str, *args: Any, **kwargs: Any) -> None:
        self._log.error(msg, *args, **kwargs)

    def exception(self, msg: str, *args: Any, **kwargs: Any) -> None:
        self._log.exception(msg, *args, **kwargs)


def get_logger(name: str) -> StructLogger:
    """Return a :class:`StructLogger` backed by the stdlib logger for *name*."""
    return StructLogger(name)
