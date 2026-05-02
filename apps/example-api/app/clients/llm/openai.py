from __future__ import annotations

import importlib.metadata
from dataclasses import dataclass

from app.config import Settings, get_settings
from app.logging import get_logger
from app.services.errors import ConfigurationError, ProviderUnavailableError

logger = get_logger(__name__)


@dataclass(frozen=True)
class OpenAITextClient:
    """Optional OpenAI implementation for projects that need an LLM provider."""

    settings: Settings

    async def complete(self, prompt: str) -> str:
        try:
            from openai import AsyncOpenAI, OpenAIError
        except ImportError as exc:
            raise ConfigurationError(
                "Install the API with the 'llm' extra to enable OpenAI support."
            ) from exc

        api_key = _resolve_api_key(self.settings)
        client = AsyncOpenAI(
            api_key=api_key,
            timeout=self.settings.openai_timeout_seconds,
            max_retries=self.settings.openai_max_retries,
        )
        try:
            response = await client.responses.create(
                model=self.settings.llm_model,
                input=prompt,
            )
        except OpenAIError as exc:
            raise ProviderUnavailableError("OpenAI request failed.") from exc

        logger.emit(
            "client.openai.request.completed",
            model=self.settings.llm_model,
            prompt_package_version=_prompt_package_version(),
            success=True,
        )
        return response.output_text


def get_llm_client() -> OpenAITextClient:
    settings = get_settings()
    if settings.llm_provider != "openai":
        raise ConfigurationError(
            "LLM_PROVIDER must be 'openai' to build OpenAI client."
        )
    return OpenAITextClient(settings=settings)


def _resolve_api_key(settings: Settings) -> str:
    if settings.ssm_openai_api_key_path:
        parameter_path = settings.ssm_openai_api_key_path
        try:
            import boto3
        except ImportError as exc:
            raise ConfigurationError(
                "Install boto3 or use OPENAI_API_KEY for local OpenAI configuration."
            ) from exc
        try:
            ssm = boto3.client("ssm", region_name=settings.aws_region)
            response = ssm.get_parameter(
                **{"Name": parameter_path, "WithDecryption": True}
            )
            return response["Parameter"]["Value"]
        except Exception as exc:
            raise ConfigurationError(
                f"Failed to retrieve OpenAI API key from SSM path "
                f"'{parameter_path}': {type(exc).__name__}"
            ) from exc

    if settings.openai_api_key:
        return settings.openai_api_key

    raise ConfigurationError("OpenAI is enabled but no API key source is configured.")


def _prompt_package_version() -> str | None:
    try:
        return importlib.metadata.version("example-prompts")
    except importlib.metadata.PackageNotFoundError:
        return None
