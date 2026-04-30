# Example Monorepo Boilerplate

A reusable full-stack monorepo starter with independently owned apps, optional AI assets, Terraform infrastructure, CI/CD workflows, and operations documentation.

## Repository Structure

```text
example-monorepo/
├── apps/
│   ├── example-api/          # FastAPI backend
│   └── example-web/          # SvelteKit static frontend
├── packages/
│   ├── example-prompts/      # Optional prompt templates and call configs
│   └── example-evals/        # Optional eval datasets and loaders
├── evals/                    # Eval runner, baselines, and process docs
├── infra/                    # Terraform bootstrap and environment layers
├── docs/operations/          # Monorepo operations guides
└── scripts/                  # Dev and ops utility scripts
```

App-specific documentation lives alongside each app in `apps/<app-name>/`.

## Prerequisites

Install [mise](https://mise.jdx.dev) to manage tool versions pinned in `mise.toml`, then trust this directory:

```bash
mise trust
```

## Quickstart

Bootstrap and check each app from the repo root:

```bash
make bootstrap APP=example-api
make check APP=example-api
make bootstrap APP=example-web
make check APP=example-web
```

Start the backend with `./apps/example-api/scripts/run.sh` and the frontend with `npm run dev` from `apps/example-web`.

## Documentation

| Document | Description |
|---|---|
| [ARCHITECTURE.md](ARCHITECTURE.md) | System design and app boundaries |
| [AGENTS.md](AGENTS.md) | Implementation rules for future AI agents |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Monorepo app contract and common targets |
| [evals/PROCESS.md](evals/PROCESS.md) | Optional eval scaffold and customization flow |
| [docs/operations/infrastructure.md](docs/operations/infrastructure.md) | Account bootstrap and CI/CD overview |
| [docs/operations/observability.md](docs/operations/observability.md) | Logging, dashboards, runbooks, and incident entry point |

## Development Principles

- Routes handle HTTP concerns and call services.
- Services own application logic and external call decisions.
- Provider-specific integrations live in clients and are optional by default.
- Structured data contracts live in schemas or shared frontend types.
- Prompts and evals are available as a scaffold, but new projects should replace the examples with their own domain assets.
