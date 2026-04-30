# Configuration

`example-api` reads configuration from environment variables and validates them at process startup.

## Core Settings

| Variable | Default | Description |
|---|---|---|
| `SERVICE_NAME` | `example-api` | Logical service name for logs and root metadata |
| `ENVIRONMENT` | `local` | Deployment environment tag |
| `VERSION` | `local` | Build/version identifier |
| `PORT` | `8000` | HTTP port |
| `CORS_ALLOW_ORIGINS` | `*` | Comma-separated browser origins |
| `LOG_LEVEL` | `INFO` | Python logging level |
| `LOG_FORMAT` | `auto` | `auto`, `json`, or `dev` |

## Optional LLM Settings

The default app does not require provider credentials.

| Variable | Default | Description |
|---|---|---|
| `LLM_PROVIDER` | `disabled` | Set to `openai` to enable the optional OpenAI client |
| `LLM_MODEL` | `gpt-4.1-mini` | Model used by the optional OpenAI client |
| `LLM_PROMPT_CALL` | `example` | Prompt call config name |
| `OPENAI_API_KEY` | unset | Local OpenAI key when `LLM_PROVIDER=openai` |
| `SSM_OPENAI_API_KEY_PATH` | unset | SSM SecureString path for deployed OpenAI key |
| `OPENAI_TIMEOUT_SECONDS` | `25` | Provider timeout |
| `OPENAI_MAX_RETRIES` | `1` | Provider retry count |
