from fastapi import HTTPException, status

from app.ai.graphs.meal_insight_graph import MealInsightGraph
from app.models.meal_report import MealReport
from app.models.meal_session import MealSession
from app.schemas.report import MealReportResponse
from app.services.user_service import UserService


class ReportService:
    def __init__(self, db):
        self.db = db
        self.user_service = UserService(db)
        self.meal_graph = MealInsightGraph()

    def get_or_build(self, meal_id: str, anonymous_user_id: str) -> MealReportResponse:
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

        report = (
            self.db.query(MealReport)
            .filter(MealReport.meal_session_id == meal.id)
            .one_or_none()
        )
        if report is None:
            report = self._build_rule_report(meal)

        return MealReportResponse(
            mealId=meal.meal_id,
            durationSec=meal.duration_sec,
            intakeGrams=meal.intake_grams,
            avgSpeed=meal.avg_speed,
            peakSpeed=meal.peak_speed,
            reminderCount=meal.reminder_count,
            summaryText=report.summary_text,
            aiSummaryText=report.ai_summary_text,
            suggestions=report.suggestions,
            reportSource=report.generated_by,
        )

    def generate_ai_summary(self, meal_id: str) -> None:
        meal = self.db.query(MealSession).filter(MealSession.meal_id == meal_id).one_or_none()
        if meal is None:
            return

        report = (
            self.db.query(MealReport)
            .filter(MealReport.meal_session_id == meal.id)
            .one_or_none()
        )
        if report is None:
            report = self._build_rule_report(meal)

        ai_output = self.meal_graph.run(
            {
                "mealId": meal.meal_id,
                "avgSpeed": meal.avg_speed,
                "peakSpeed": meal.peak_speed,
                "reminderCount": meal.reminder_count,
                "durationSec": meal.duration_sec,
                "intakeGrams": meal.intake_grams,
            }
        )
        report.ai_summary_text = ai_output["aiSummaryText"]
        report.suggestions = ai_output["suggestions"]
        report.generated_by = "rulePlusAiStub"
        self.db.commit()

    def _build_rule_report(self, meal: MealSession) -> MealReport:
        summary_text = self._build_rule_summary(meal)
        suggestions = self._build_rule_suggestions(meal)

        report = MealReport(
            meal_session_id=meal.id,
            summary_text=summary_text,
            ai_summary_text=None,
            suggestions=suggestions,
            generated_by="ruleOnly",
        )
        self.db.add(report)
        self.db.commit()
        self.db.refresh(report)
        return report

    def _build_rule_summary(self, meal: MealSession) -> str:
        if meal.avg_speed >= 18:
            return "本餐速度明显偏快，建议下次拉长咀嚼和停顿。"
        if meal.reminder_count > 0:
            return "本餐节奏略快，但提醒已在中途介入。"
        return "本餐整体节奏较稳定，可继续保持。"

    def _build_rule_suggestions(self, meal: MealSession) -> list[str]:
        suggestions = ["下一餐继续观察前 5 分钟的进食速度。"]
        if meal.avg_speed >= 18:
            suggestions.append("尝试每 3 到 5 口主动放下餐具一次。")
        if meal.reminder_count == 0:
            suggestions.append("如果再次出现快吃倾向，可考虑更早触发提醒。")
        return suggestions
