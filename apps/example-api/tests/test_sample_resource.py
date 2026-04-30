from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_sample_resource_success():
    response = client.get("/sample-resource")
    assert response.status_code == 200
    assert response.json() == {
        "id": "sample-resource",
        "name": "Example Resource",
        "description": "A deterministic response used to demonstrate the API contract.",
        "tags": ["boilerplate", "example", "api"],
    }


def test_sample_resource_rejects_wrong_method():
    response = client.post("/sample-resource", json={})
    assert response.status_code == 405
