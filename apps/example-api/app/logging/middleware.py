from __future__ import annotations

import time
import uuid
from typing import Any

from starlette.requests import Request
from starlette.types import ASGIApp, Receive, Scope, Send

from app.logging.context import reset_request_context, set_request_context
from app.logging.logger import get_logger

logger = get_logger(__name__)


class RequestContextMiddleware:
    """Pure ASGI middleware that establishes per-request observability context.

    Implemented as a raw ASGI callable (not BaseHTTPMiddleware) so that the
    inner application — including FastAPI's exception handlers — runs to full
    completion before ``http.request.completed`` is emitted.  This guarantees
    that exception events always appear in the log before the terminal summary
    line.

    On each request it:
    - Extracts or generates an ``X-Request-ID`` and appends it to the response
      headers.
    - Populates the :mod:`~app.logging.context` store so that every log line
      within the request lifecycle is automatically tagged with ``request_id``,
      ``method``, and ``path``.
    - Emits ``http.request.received`` and ``http.request.completed`` structured
      events with status code and latency.
    """

    def __init__(self, app: ASGIApp) -> None:
        self.app = app

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return

        request = Request(scope)
        request_id = request.headers.get("X-Request-ID") or str(uuid.uuid4())
        token = set_request_context(
            request_id=request_id,
            method=request.method,
            path=request.url.path,
        )

        logger.emit(
            "http.request.received", method=request.method, path=request.url.path
        )

        start = time.perf_counter()
        status_code = 500

        async def capture_send(message: dict[str, Any]) -> None:
            nonlocal status_code
            if message["type"] == "http.response.start":
                status_code = message["status"]
                headers = list(message.get("headers", []))
                headers.append((b"x-request-id", request_id.encode()))
                message = {**message, "headers": headers}
            await send(message)

        try:
            await self.app(scope, receive, capture_send)
        finally:
            elapsed_ms = round((time.perf_counter() - start) * 1000)
            logger.emit(
                "http.request.completed",
                status_code=status_code,
                latency_ms=elapsed_ms,
            )
            reset_request_context(token)
