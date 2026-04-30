# Observability

The boilerplate emits structured logs from both the API and browser demo.

## Event Naming

Use dot-separated event names with stable attributes, for example:

- `http.request.completed`
- `api.health.request.completed`
- `api.sample_resource.request.completed`
- `client.openai.request.completed` for optional provider calls

## Incident Entry Point

1. Check the app endpoint with `make smoke APP=<app> APP_ENDPOINT=<url>`.
2. Inspect CloudWatch logs for the Lambda function or browser console logs for the web demo.
3. Use app runbooks under `apps/<app>/docs/operations/` for app-specific details.
