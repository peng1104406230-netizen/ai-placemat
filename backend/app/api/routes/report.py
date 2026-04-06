from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.api.deps import get_db
from app.schemas.report import MealReportResponse
from app.services.report_service import ReportService

router = APIRouter()


@router.get("/{meal_id}", response_model=MealReportResponse)
def get_report(
    meal_id: str,
    anonymous_user_id: str = Query(..., alias="anonymousUserId"),
    db: Session = Depends(get_db),
) -> MealReportResponse:
    return ReportService(db).get_or_build(meal_id=meal_id, anonymous_user_id=anonymous_user_id)
