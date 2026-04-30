from pydantic import BaseModel, Field


class HealthResponse(BaseModel):
    status: str
    version: str = Field(
        default="local",
        description="Build SHA, or 'local' when running outside a pipeline.",
    )
