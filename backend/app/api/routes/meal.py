from fastapi import APIRouter, BackgroundTasks, Depends, Query
from sqlalchemy.orm import Session

from app.api.deps import get_db
from app.schemas.meal import MealDetailResponse, MealUploadRequest, MealUploadResponse
from app.services.meal_service import MealService

router = APIRouter()


@router.post("/upload", response_model=MealUploadResponse)
def upload_meal(
    payload: MealUploadRequest,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
) -> MealUploadResponse:
    return MealService(db).upload(payload, background_tasks)


@router.get("/{meal_id}", response_model=MealDetailResponse)
def get_meal(
    meal_id: str,
    anonymous_user_id: str = Query(..., alias="anonymousUserId"),
    db: Session = Depends(get_db),
) -> MealDetailResponse:
    return MealService(db).get_meal(meal_id=meal_id, anonymous_user_id=anonymous_user_id)
