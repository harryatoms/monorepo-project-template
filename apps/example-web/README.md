# example-web

A SvelteKit static demo app for the generic monorepo boilerplate. It calls the example API from the browser and displays root metadata, health, and sample-resource data.

## Quickstart

Run from the repo root:

```bash
make bootstrap APP=example-web
make check APP=example-web
```

For local development:

```bash
cd apps/example-web
npm run dev
```

Set `PUBLIC_API_URL` in `.env` if the API is not running at `http://localhost:8000`.
