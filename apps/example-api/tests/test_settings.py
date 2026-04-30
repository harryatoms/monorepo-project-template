import pytest
from pydantic import ValidationError

from app.config import Settings, _reset_settings, get_settings


@pytest.fixture(autouse=True)
def reset_singleton():
    _reset_settings()
    yield
    _reset_settings()


def test_valid_defaults_do_not_require_llm_credentials():
    s = Settings()
    assert s.service_name == "example-api"
    assert s.llm_provider == "disabled"
    assert s.openai_api_key is None
    assert s.ssm_openai_api_key_path is None
    assert s.port == 8000


def test_openai_provider_requires_credential_source():
    with pytest.raises(ValidationError) as exc_info:
        Settings(llm_provider="openai")
    assert "OPENAI_API_KEY" in str(exc_info.value)


def test_openai_provider_allows_plain_api_key():
    s = Settings(llm_provider="openai", openai_api_key="dummy-openai-key")
    assert s.llm_provider == "openai"
    assert s.openai_api_key == "dummy-openai-key"


def test_openai_provider_allows_ssm_path():
    s = Settings(
        llm_provider="openai",
        ssm_openai_api_key_path="/example-monorepo/staging/OPENAI_API_KEY",
    )
    assert s.ssm_openai_api_key_path == "/example-monorepo/staging/OPENAI_API_KEY"


def test_log_level_case_normalisation():
    assert Settings(log_level="debug").log_level == "DEBUG"
    assert Settings(log_level="Warning").log_level == "WARNING"


def test_log_format_case_normalisation():
    assert Settings(log_format="JSON").log_format == "json"
    assert Settings(log_format="Dev").log_format == "dev"


def test_invalid_log_level_raises():
    with pytest.raises(ValidationError):
        Settings(log_level="VERBOSE")


def test_invalid_log_format_raises():
    with pytest.raises(ValidationError):
        Settings(log_format="plain")


def test_empty_environment_raises():
    with pytest.raises(ValidationError, match="ENVIRONMENT"):
        Settings(environment="")


def test_empty_service_name_raises():
    with pytest.raises(ValidationError, match="SERVICE_NAME"):
        Settings(service_name="   ")


def test_port_boundary_values():
    assert Settings(port=1).port == 1
    assert Settings(port=65535).port == 65535


def test_invalid_port_raises():
    with pytest.raises(ValidationError):
        Settings(port=0)
    with pytest.raises(ValidationError):
        Settings(port=65536)


def test_invalid_timeout_and_retries_raise():
    with pytest.raises(ValidationError):
        Settings(openai_timeout_seconds=0)
    with pytest.raises(ValidationError):
        Settings(openai_max_retries=-1)


def test_from_env_applies_defaults(monkeypatch):
    monkeypatch.delenv("LLM_PROVIDER", raising=False)
    monkeypatch.delenv("OPENAI_API_KEY", raising=False)
    monkeypatch.delenv("SSM_OPENAI_API_KEY_PATH", raising=False)
    s = Settings.from_env()
    assert s.service_name == "example-api"
    assert s.llm_provider == "disabled"


def test_from_env_reads_openai_provider(monkeypatch):
    monkeypatch.setenv("LLM_PROVIDER", "openai")
    monkeypatch.setenv("OPENAI_API_KEY", "dummy-openai-key-from-env")
    s = Settings.from_env()
    assert s.llm_provider == "openai"
    assert s.openai_api_key == "dummy-openai-key-from-env"


def test_get_settings_singleton(monkeypatch):
    monkeypatch.setenv("SERVICE_NAME", "custom-example-api")
    first = get_settings()
    second = get_settings()
    assert first is second
    assert first.service_name == "custom-example-api"
