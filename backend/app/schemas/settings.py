from datetime import datetime

from pydantic import BaseModel, Field

from app.schemas.common import QuietHours


class ReminderSettingsBase(BaseModel):
    anonymous_user_id: str = Field(..., alias="anonymousUserId")
    reminder_enabled: bool = Field(..., alias="reminderEnabled")
    reminder_frequency: int = Field(..., alias="reminderFrequency")
    reminder_text: str = Field(..., alias="reminderText")
    voice_enabled: bool = Field(..., alias="voiceEnabled")
    quiet_hours: QuietHours = Field(..., alias="quietHours")

    model_config = {
        "populate_by_name": True,
    }


class ReminderSettingsUpdate(ReminderSettingsBase):
    pass


class ReminderSettingsResponse(ReminderSettingsBase):
    updated_at: datetime = Field(..., alias="updatedAt")
    sync_state: str = Field(default="synced", alias="syncState")
