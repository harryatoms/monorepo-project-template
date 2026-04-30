from app.schemas.sample_resource import SampleResourceResponse


def get_sample_resource() -> SampleResourceResponse:
    """Return deterministic data for the boilerplate demo endpoint."""
    return SampleResourceResponse(
        id="sample-resource",
        name="Example Resource",
        description="A deterministic response used to demonstrate the API contract.",
        tags=["boilerplate", "example", "api"],
    )
