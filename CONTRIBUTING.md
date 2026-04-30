# Contributing

This monorepo treats each app as an independently checkable and deployable unit.

## Common Commands

Run commands from the repo root:

```bash
make bootstrap APP=example-api
make check APP=example-api
make bootstrap APP=example-web
make check APP=example-web
make check-all
```

## App Contract

Each app should provide a local `Makefile` with these targets when applicable:

- `bootstrap`
- `check`
- `build`
- `deploy`
- `smoke`
- `infra-init`, `infra-plan`, `infra-apply`, `infra-plan-destroy`, `infra-destroy`

## Adding Features

Keep HTTP routes thin, put business logic in services, and define structured contracts in schemas/types. If a feature integrates with an external provider, isolate that provider in `clients/` and make it mockable in tests.

## Optional Evals

The default eval scaffold is a deterministic smoke test. Replace the example prompt, dataset, runner, and baseline when a project adds real AI behavior.
