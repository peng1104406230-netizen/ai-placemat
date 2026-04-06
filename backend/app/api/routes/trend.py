from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.api.deps import get_db
from app.schemas.trend import TrendSummaryResponse
from app.services.trend_service import TrendService

router = APIRouter()


@router.get("/7d", response_model=TrendSummaryResponse)
def get_trend_7d(
    anonymous_user_id: str = Query(..., alias="anonymousUserId"),
    db: Session = Depends(get_db),
) -> TrendSummaryResponse:
    return TrendService(db).get_or_build_7d(anonymous_user_id)
