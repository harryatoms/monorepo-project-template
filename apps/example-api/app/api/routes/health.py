from fastapi import APIRouter

from app.logging.context import get_build
from app.schemas.health import HealthResponse

router = APIRouter()


@router.get("/health", tags=["meta"], response_model=HealthResponse)
async def health() -> HealthResponse:
    return HealthResponse(status="ok", version=get_build())
