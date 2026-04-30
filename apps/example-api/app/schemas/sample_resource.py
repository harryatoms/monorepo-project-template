from pydantic import BaseModel, Field


class SampleResourceResponse(BaseModel):
    id: str = Field(description="Stable identifier for the example resource.")
    name: str
    description: str
    tags: list[str] = Field(default_factory=list)
