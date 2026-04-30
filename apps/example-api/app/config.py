"""Central configuration for the example API."""
from __future__ import annotations

import os
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator


class Settings(BaseModel):
    model_config = ConfigDict(frozen=True)

    # --- Runtime context ---
    environment: str = "local"
    version: str = "local"
    service_name: str = "example-api"

    # --- Logging ---
    log_level: Literal["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"] = "INFO"
    log_format: Literal["json", "dev", "auto"] = "auto"

    # --- Server ---
    port: int = Field(default=8000, ge=1, le=65535)
    cors_allow_origins: list[str] = Field(default_factory=lambda: ["*"])

    # --- Optional LLM provider ---
    llm_provider: Literal["disabled", "openai"] = "disabled"
    llm_model: str = "gpt-4.1-mini"
    llm_prompt_call: str = "example"
    openai_api_key: str | None = None
    ssm_openai_api_key_path: str | None = None
    aws_region: str = "us-east-1"
    openai_timeout_seconds: float = Field(default=25.0, gt=0)
    openai_max_retries: int = Field(default=1, ge=0)

    @field_validator("log_level", mode="before")
    @classmethod
    def _normalise_log_level(cls, v: object) -> object:
        return v.upper() if isinstance(v, str) else v

    @field_validator("log_format", mode="before")
    @classmethod
    def _normalise_log_format(cls, v: object) -> object:
        return v.lower() if isinstance(v, str) else v

    @field_validator("llm_provider", mode="before")
    @classmethod
    def _normalise_llm_provider(cls, v: object) -> object:
        return v.lower() if isinstance(v, str) else v

    @field_validator("environment")
    @classmethod
    def _environment_not_empty(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("ENVIRONMENT must not be empty or whitespace-only")
        return v

    @field_validator("service_name")
    @classmethod
    def _service_name_not_empty(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("SERVICE_NAME must not be empty or whitespace-only")
        return v

    @model_validator(mode="after")
    def _validate_optional_llm_credentials(self) -> "Settings":
        if self.llm_provider == "openai" and not (
            self.openai_api_key or self.ssm_openai_api_key_path
        ):
            raise ValueError(
                "OPENAI_API_KEY or SSM_OPENAI_API_KEY_PATH is required when "
                "LLM_PROVIDER=openai. Leave LLM_PROVIDER=disabled for the "
                "default boilerplate app."
            )
        return self

    @classmethod
    def from_env(cls) -> "Settings":
        return cls(
            environment=os.environ.get("ENVIRONMENT", "local"),
            version=os.environ.get("VERSION", "local"),
            service_name=os.environ.get("SERVICE_NAME", "example-api"),
            log_level=os.environ.get("LOG_LEVEL", "INFO"),
            log_format=os.environ.get("LOG_FORMAT", "auto"),
            port=os.environ.get("PORT", "8000"),
            cors_allow_origins=[
                o.strip()
                for o in os.environ.get("CORS_ALLOW_ORIGINS", "*").split(",")
                if o.strip()
            ],
            llm_provider=os.environ.get("LLM_PROVIDER", "disabled"),
            llm_model=os.environ.get("LLM_MODEL", "gpt-4.1-mini"),
            llm_prompt_call=os.environ.get("LLM_PROMPT_CALL", "example"),
            openai_api_key=os.environ.get("OPENAI_API_KEY") or None,
            ssm_openai_api_key_path=os.environ.get("SSM_OPENAI_API_KEY_PATH") or None,
            aws_region=os.environ.get("AWS_REGION", "us-east-1"),
            openai_timeout_seconds=os.environ.get("OPENAI_TIMEOUT_SECONDS", "25"),
            openai_max_retries=os.environ.get("OPENAI_MAX_RETRIES", "1"),
        )


_settings: Settings | None = None


def get_settings() -> Settings:
    global _settings
    if _settings is None:
        _settings = Settings.from_env()
    return _settings


def _reset_settings() -> None:
    global _settings
    _settings = None
