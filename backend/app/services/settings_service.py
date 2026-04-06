from app.models.user_settings import UserSettings
from app.schemas.settings import ReminderSettingsResponse, ReminderSettingsUpdate
from app.services.user_service import UserService


class SettingsService:
    def __init__(self, db):
        self.db = db
        self.user_service = UserService(db)

    def get_or_create(self, anonymous_user_id: str) -> ReminderSettingsResponse:
        user = self.user_service.get_or_create_user(anonymous_user_id)
        settings = (
            self.db.query(UserSettings)
            .filter(UserSettings.user_id == user.id)
            .one_or_none()
        )

        if settings is None:
            settings = UserSettings(user_id=user.id)
            self.db.add(settings)
            self.db.commit()
            self.db.refresh(settings)

        return self._to_response(anonymous_user_id, settings)

    def upsert(self, payload: ReminderSettingsUpdate) -> ReminderSettingsResponse:
        user = self.user_service.get_or_create_user(payload.anonymous_user_id)
        settings = (
            self.db.query(UserSettings)
            .filter(UserSettings.user_id == user.id)
            .one_or_none()
        )

        if settings is None:
            settings = UserSettings(user_id=user.id)
            self.db.add(settings)

        settings.reminder_enabled = payload.reminder_enabled
        settings.reminder_frequency = payload.reminder_frequency
        settings.reminder_text = payload.reminder_text
        settings.voice_enabled = payload.voice_enabled
        settings.quiet_hours = payload.quiet_hours.model_dump()
        self.db.commit()
        self.db.refresh(settings)

        return self._to_response(payload.anonymous_user_id, settings)

    def _to_response(
        self,
        anonymous_user_id: str,
        settings: UserSettings,
    ) -> ReminderSettingsResponse:
        return ReminderSettingsResponse(
            anonymousUserId=anonymous_user_id,
            reminderEnabled=settings.reminder_enabled,
            reminderFrequency=settings.reminder_frequency,
            reminderText=settings.reminder_text,
            voiceEnabled=settings.voice_enabled,
            quietHours=settings.quiet_hours,
            updatedAt=settings.updated_at,
            syncState="synced",
        )
