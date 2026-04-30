# Observability

`example-api` emits structured JSON logs with request IDs, service name, environment, and event-specific attributes.

## Useful Events

- `http.request.completed`
- `http.request.validation_failed`
- `application.request.failed`
- `provider.request.failed`
- `provider.response.invalid`
- `client.openai.request.completed` when optional LLM support is enabled

## Smoke Test

```bash
make smoke APP=example-api APP_ENDPOINT=<api-url>
```

## Incident Checklist

1. Confirm `/health` and `/sample-resource` with the smoke test.
2. Check Lambda logs for `server.unhandled_exception` or `application.request.failed`.
3. Inspect API Gateway and Lambda 5xx metrics.
4. Roll back with `make rollback APP=example-api VERSION=<previous-version>` if the issue followed a deploy.
