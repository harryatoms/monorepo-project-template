# syntax=docker/dockerfile:1

FROM public.ecr.aws/awsguru/aws-lambda-adapter:1.0.0-rc1 AS lwa

FROM python:3.13-slim AS builder

WORKDIR /build

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY apps/example-api/pyproject.toml apps/example-api/pyproject.toml
COPY apps/example-api/app             apps/example-api/app

RUN pip install --no-cache-dir ./apps/example-api

FROM python:3.13-slim AS runtime

ARG VERSION
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH" \
    PORT="8000" \
    VERSION=${VERSION}

COPY --from=lwa /lambda-adapter /opt/extensions/lambda-adapter

RUN groupadd --system --gid 1001 appgroup \
 && useradd  --system --uid 1001 --gid appgroup --no-create-home appuser

COPY --from=builder /opt/venv /opt/venv

WORKDIR /var/task
USER appuser

EXPOSE 8000

CMD ["sh", "-c", "exec uvicorn app.main:app --host 0.0.0.0 --port \"$PORT\" --log-level info"]
