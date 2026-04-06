from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.api.deps import get_db
from app.schemas.settings import ReminderSettingsResponse, ReminderSettingsUpdate
from app.services.settings_service import SettingsService

router = APIRouter()


@router.get("", response_model=ReminderSettingsResponse)
def get_settings(
    anonymous_user_id: str = Query(..., alias="anonymousUserId"),
    db: Session = Depends(get_db),
) -> ReminderSettingsResponse:
    return SettingsService(db).get_or_create(anonymous_user_id)


@router.put("", response_model=ReminderSettingsResponse, status_code=status.HTTP_200_OK)
def put_settings(
    payload: ReminderSettingsUpdate,
    db: Session = Depends(get_db),
) -> ReminderSettingsResponse:
    return SettingsService(db).upsert(payload)
