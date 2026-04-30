# example-api

A generic FastAPI service for this monorepo boilerplate. It exposes operational metadata, a health check, and a deterministic sample resource endpoint that demonstrates the route -> service -> schema pattern.

## Quickstart

Run from the repo root:

```bash
make bootstrap APP=example-api
./apps/example-api/scripts/run.sh
```

The API will be available at `http://localhost:8000`.

## Endpoints

| Method | Path | Description |
|---|---|---|
| `GET` | `/` | Root service metadata |
| `GET` | `/health` | Health check |
| `GET` | `/sample-resource` | Deterministic example resource |

## Configuration

Copy the example environment file if you want local overrides:

```bash
cp apps/example-api/.env.example apps/example-api/.env
```

No secrets are required for the default boilerplate app. Optional LLM provider settings are documented in [docs/operations/configuration.md](docs/operations/configuration.md).

## Running tests

```bash
make check APP=example-api
```

## Project layout

```text
example-api/
├── app/
│   ├── api/routes/     # HTTP route handlers
│   ├── clients/        # Optional provider clients
│   ├── schemas/        # Pydantic request/response models
│   └── services/       # Business logic
├── tests/
├── scripts/
├── docs/operations/
├── Dockerfile
├── Makefile
├── pyproject.toml
└── server.py
```
