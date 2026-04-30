from fastapi import APIRouter

from app.schemas.sample_resource import SampleResourceResponse
from app.services.sample_resource import get_sample_resource

router = APIRouter(prefix="/sample-resource", tags=["sample"])


@router.get("", response_model=SampleResourceResponse)
async def sample_resource() -> SampleResourceResponse:
    return get_sample_resource()
