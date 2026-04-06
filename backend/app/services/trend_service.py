from sqlalchemy import desc

from app.ai.graphs.trend_insight_graph import TrendInsightGraph
from app.models.meal_session import MealSession
from app.models.trend_snapshot import TrendSnapshot
from app.schemas.trend import TrendSummaryResponse
from app.services.user_service import UserService


class TrendService:
    def __init__(self, db):
        self.db = db
        self.user_service = UserService(db)
        self.trend_graph = TrendInsightGraph()

    def get_or_build_7d(self, anonymous_user_id: str) -> TrendSummaryResponse:
        user = self.user_service.get_or_create_user(anonymous_user_id)
        snapshot = (
            self.db.query(TrendSnapshot)
            .filter(
                TrendSnapshot.user_id == user.id,
                TrendSnapshot.window_days == 7,
            )
            .order_by(desc(TrendSnapshot.created_at))
            .first()
        )

        if snapshot is None:
            snapshot = self.refresh_7d_snapshot(anonymous_user_id)

        return TrendSummaryResponse(
            anonymousUserId=anonymous_user_id,
            avgSpeed=snapshot.avg_speed,
            fastMealCount=snapshot.fast_meal_count,
            improvementRate=snapshot.improvement_rate,
            summaryText=snapshot.summary_text,
            aiSummaryText=snapshot.ai_summary_text,
            windowDays=snapshot.window_days,
            source="ruleOnly" if snapshot.ai_summary_text is None else "rulePlusAiStub",
        )

    def refresh_7d_snapshot(self, anonymous_user_id: str) -> TrendSnapshot:
        user = self.user_service.get_or_create_user(anonymous_user_id)
        meals = (
            self.db.query(MealSession)
            .filter(MealSession.user_id == user.id)
            .order_by(desc(MealSession.end_time))
            .limit(7)
            .all()
        )

        avg_speed = (
            sum(meal.avg_speed for meal in meals) / len(meals)
            if meals
            else 0.0
        )
        fast_meal_count = sum(1 for meal in meals if meal.avg_speed >= 18)
        improvement_rate = self._compute_improvement_rate(meals)
        summary_text = self._build_rule_summary(meals, avg_speed, fast_meal_count)

        snapshot = TrendSnapshot(
            user_id=user.id,
            window_days=7,
            avg_speed=avg_speed,
            fast_meal_count=fast_meal_count,
            improvement_rate=improvement_rate,
            summary_text=summary_text,
            ai_summary_text=None,
        )
        self.db.add(snapshot)
        self.db.commit()
        self.db.refresh(snapshot)
        return snapshot

    def generate_ai_summary(self, anonymous_user_id: str) -> None:
        user = self.user_service.get_or_create_user(anonymous_user_id)
        snapshot = (
            self.db.query(TrendSnapshot)
            .filter(
                TrendSnapshot.user_id == user.id,
                TrendSnapshot.window_days == 7,
            )
            .order_by(desc(TrendSnapshot.created_at))
            .first()
        )
        if snapshot is None:
            snapshot = self.refresh_7d_snapshot(anonymous_user_id)

        ai_output = self.trend_graph.run(
            {
                "anonymousUserId": anonymous_user_id,
                "avgSpeed": snapshot.avg_speed,
                "fastMealCount": snapshot.fast_meal_count,
                "improvementRate": snapshot.improvement_rate,
            }
        )
        snapshot.ai_summary_text = ai_output["aiSummaryText"]
        self.db.commit()

    def _compute_improvement_rate(self, meals: list[MealSession]) -> float:
        if len(meals) < 2:
            return 0.0
        newest = meals[0].avg_speed
        oldest = meals[-1].avg_speed
        if oldest <= 0:
            return 0.0
        return round((oldest - newest) / oldest, 4)

    def _build_rule_summary(
        self,
        meals: list[MealSession],
        avg_speed: float,
        fast_meal_count: int,
    ) -> str:
        if not meals:
            return "最近 7 天样本不足，先继续积累餐次数据。"
        if fast_meal_count >= max(1, len(meals) // 2):
            return "最近 7 天快吃餐次偏多，建议优先稳定开餐前半段速度。"
        if avg_speed <= 12:
            return "最近 7 天整体节奏较稳，当前改善方向有效。"
        return "最近 7 天有一定改善，但节奏稳定性仍需继续观察。"
