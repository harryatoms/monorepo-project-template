from fastapi.testclient import TestClient

import app.logging.context as log_ctx
from app.main import app

client = TestClient(app)


def test_root():
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["service"] == "example-api"
    assert "version" in data


def test_health(monkeypatch):
    monkeypatch.setattr(log_ctx, "_build", None)
    monkeypatch.delenv("VERSION", raising=False)
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert data["version"] == "local"


def test_health_with_version(monkeypatch):
    monkeypatch.setattr(log_ctx, "_build", None)
    monkeypatch.setenv("VERSION", "abc1234")
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert data["version"] == "abc1234"
