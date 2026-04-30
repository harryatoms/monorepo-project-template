import pytest

from app.config import _reset_settings


@pytest.fixture(autouse=True)
def reset_settings_singleton():
    _reset_settings()
    yield
    _reset_settings()
