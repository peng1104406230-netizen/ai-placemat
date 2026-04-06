from pydantic import BaseModel, Field


class MealReportResponse(BaseModel):
    meal_id: str = Field(..., alias="mealId")
    duration_sec: int = Field(..., alias="durationSec")
    intake_grams: float = Field(..., alias="intakeGrams")
    avg_speed: float = Field(..., alias="avgSpeed")
    peak_speed: float = Field(..., alias="peakSpeed")
    reminder_count: int = Field(..., alias="reminderCount")
    summary_text: str = Field(..., alias="summaryText")
    ai_summary_text: str | None = Field(default=None, alias="aiSummaryText")
    suggestions: list[str]
    report_source: str = Field(..., alias="reportSource")

    model_config = {"populate_by_name": True}
