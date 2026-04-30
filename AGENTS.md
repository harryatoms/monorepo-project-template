# AGENTS.md

This repository is a generic full-stack monorepo boilerplate.

## Architecture Overview

The API follows a strict separation of responsibilities:

- routes handle HTTP concerns only
- schemas define request and response contracts
- services contain business logic and own external call decisions
- clients implement provider-specific integrations invoked by services

Routes must remain thin and should not contain business logic.

## Directory Responsibilities

`apps/example-api/app/api/routes`
HTTP route handlers only.

`apps/example-api/app/schemas`
Pydantic models defining API contracts.

`apps/example-api/app/services`
Business logic and orchestration.

`apps/example-api/app/clients`
Optional provider-specific clients.

`apps/example-web/src/routes`
SvelteKit page components.

`apps/example-web/src/lib`
Typed API client, shared types, and structured browser logger.

`packages/example-prompts`
Optional installable package for prompt templates and call configs. Import with `from example_prompts import load_prompt, load_call`.

`packages/example-evals`
Optional installable package for eval datasets and loaders. Import with `from example_evals import load_scenarios`.

## Current Example Surface

The API exposes:

- `GET /`
- `GET /health`
- `GET /sample-resource`

The frontend demonstrates calling those endpoints directly from the browser.

## Implementation Rules

When implementing new features:

1. Define request and response schemas first.
2. Implement business logic in a service module.
3. Keep route handlers thin.
4. Add focused tests for new endpoints.
5. Avoid introducing heavy frameworks unless required.

Do not add LangChain, Celery, or database ORMs until the architecture requires them.
