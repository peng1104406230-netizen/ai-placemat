from fastapi import BackgroundTasks, HTTPException, status

from app.db.session import SessionLocal
from app.models.meal_session import MealSession
from app.schemas.meal import MealDetailResponse, MealUploadRequest, MealUploadResponse
from app.services.report_service import ReportService
from app.services.trend_service import TrendService
from app.services.user_service import UserService


class MealService:
    def __init__(self, db):
        self.db = db
        self.user_service = UserService(db)

    def upload(
        self,
        payload: MealUploadRequest,
        background_tasks: BackgroundTasks,
    ) -> MealUploadResponse:
        user = self.user_service.get_or_create_user(payload.anonymous_user_id)
        meal = (
            self.db.query(MealSession)
            .filter(MealSession.meal_id == payload.meal_id)
            .one_or_none()
        )

        if meal is None:
            meal = MealSession(meal_id=payload.meal_id, user_id=user.id)
            self.db.add(meal)

        meal.start_time = payload.start_time
        meal.end_time = payload.end_time
        meal.duration_sec = payload.duration_sec
        meal.intake_grams = payload.intake_grams
        meal.avg_speed = payload.avg_speed
        meal.peak_speed = payload.peak_speed
        meal.reminder_count = payload.reminder_count
        meal.samples = [sample.model_dump(by_alias=True, mode="json") for sample in payload.samples]
        meal.events = [event.model_dump(by_alias=True, mode="json") for event in payload.events]
        self.db.commit()
        self.db.refresh(meal)

        background_tasks.add_task(self._generate_report_task, meal.meal_id)
        background_tasks.add_task(self._refresh_trend_task, payload.anonymous_user_id)

        return MealUploadResponse(
            anonymousUserId=payload.anonymous_user_id,
            mealId=payload.meal_id,
            status="accepted",
            reportStatus="queued",
            trendStatus="queued",
        )

    def get_meal(self, meal_id: str, anonymous_user_id: str) -> MealDetailResponse:
        user = self.user_service.get_or_create_user(anonymous_user_id)
        meal = (
            self.db.query(MealSession)
            .filter(
                MealSession.meal_id == meal_id,
                MealSession.user_id == user.id,
            )
            .one_or_none()
        )
        if meal is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Meal {meal_id} not found for anonymous user.",
            )

        return MealDetailResponse(
            anonymousUserId=anonymous_user_id,
            mealId=meal.meal_id,
            startTime=meal.start_time,
            endTime=meal.end_time,
            durationSec=meal.duration_sec,
            intakeGrams=meal.intake_grams,
            avgSpeed=meal.avg_speed,
            peakSpeed=meal.peak_speed,
            reminderCount=meal.reminder_count,
            samples=meal.samples,
            events=meal.events,
        )

    def _generate_report_task(self, meal_id: str) -> None:
        db = SessionLocal()
        try:
            ReportService(db).generate_ai_summary(meal_id)
        finally:
            db.close()

    def _refresh_trend_task(self, anonymous_user_id: str) -> None:
        db = SessionLocal()
        try:
            trend_service = TrendService(db)
            trend_service.refresh_7d_snapshot(anonymous_user_id)
            trend_service.generate_ai_summary(anonymous_user_id)
        finally:
            db.close()
