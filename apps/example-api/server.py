"""Uvicorn entry point for local development.

Runs the app with structured JSON logging across all output — including
uvicorn's own startup, shutdown, and error messages — so the full log
stream is uniform and parseable from the first line.
"""
import uvicorn

from app.logging.setup import build_uvicorn_log_config

if __name__ == "__main__":
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_config=build_uvicorn_log_config(),
    )
