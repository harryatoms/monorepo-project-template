# ruff: noqa: E402
import logging

from dotenv import load_dotenv

load_dotenv()

from app.config import get_settings

_settings = get_settings()

from app.logging.setup import configure_logging

configure_logging(level=getattr(logging, _settings.log_level, logging.INFO))

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.api.routes.health import router as health_router
from app.api.routes.sample_resource import router as sample_resource_router
from app.logging import get_logger
from app.logging.context import get_build, get_request_context
from app.logging.middleware import RequestContextMiddleware
from app.services.errors import (
    ApplicationError,
    ConfigurationError,
    InvalidProviderResponseError,
    ProviderUnavailableError,
)

logger = get_logger(__name__)

app = FastAPI(
    title="Example API",
    description="Generic FastAPI service for the monorepo boilerplate.",
    version="0.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=_settings.cors_allow_origins,
    allow_methods=["POST", "GET", "OPTIONS"],
    allow_headers=["Content-Type", "X-Request-ID"],
)
app.add_middleware(RequestContextMiddleware)

app.include_router(health_router)
app.include_router(sample_resource_router)


def _error_json(request_id: str, code: str, message: str, status: int) -> JSONResponse:
    return JSONResponse(
        status_code=status,
        content={
            "error": {"code": code, "message": message},
            "request_id": request_id,
        },
    )


@app.exception_handler(RequestValidationError)
async def validation_error_handler(
    request: Request, exc: RequestValidationError
) -> JSONResponse:
    request_id = get_request_context().get("request_id", "unknown")
    logger.emit(
        "http.request.validation_failed",
        level="warning",
        errors=exc.errors(),
    )
    return _error_json(
        request_id,
        code="validation_failed",
        message="The request body is invalid.",
        status=422,
    )


@app.exception_handler(ProviderUnavailableError)
async def provider_unavailable_handler(
    request: Request, exc: ProviderUnavailableError
) -> JSONResponse:
    request_id = get_request_context().get("request_id", "unknown")
    logger.emit(
        "provider.request.failed",
        level="error",
        error_code="provider_unavailable",
        error_message=str(exc),
    )
    return _error_json(
        request_id,
        code="provider_unavailable",
        message="An upstream provider is temporarily unavailable.",
        status=502,
    )


@app.exception_handler(InvalidProviderResponseError)
async def invalid_provider_response_handler(
    request: Request, exc: InvalidProviderResponseError
) -> JSONResponse:
    request_id = get_request_context().get("request_id", "unknown")
    logger.emit(
        "provider.response.invalid",
        level="error",
        error_code="invalid_provider_response",
        error_message=str(exc),
    )
    return _error_json(
        request_id,
        code="invalid_provider_response",
        message="The upstream provider response was invalid.",
        status=502,
    )


@app.exception_handler(ConfigurationError)
async def configuration_error_handler(
    request: Request, exc: ConfigurationError
) -> JSONResponse:
    request_id = get_request_context().get("request_id", "unknown")
    logger.emit(
        "dependency.configuration_failed",
        level="error",
        error_code="configuration_failed",
        error_message=str(exc),
    )
    return _error_json(
        request_id,
        code="configuration_failed",
        message="A required service dependency is not configured.",
        status=500,
    )


@app.exception_handler(ApplicationError)
async def application_error_handler(
    request: Request, exc: ApplicationError
) -> JSONResponse:
    request_id = get_request_context().get("request_id", "unknown")
    logger.emit(
        "application.request.failed",
        level="error",
        error_type=type(exc).__name__,
        error_message=str(exc),
    )
    return _error_json(
        request_id,
        code="application_error",
        message="Unable to complete the request.",
        status=500,
    )


@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    request_id = get_request_context().get("request_id", "unknown")
    logger.emit(
        "server.unhandled_exception",
        level="error",
        exc=exc,
        error_type=type(exc).__name__,
    )
    return _error_json(
        request_id,
        code="internal_error",
        message="An unexpected error occurred.",
        status=500,
    )


@app.get("/", tags=["meta"])
async def root() -> dict[str, str]:
    return {"service": _settings.service_name, "version": get_build()}
