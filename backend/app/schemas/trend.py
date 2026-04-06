from pydantic import BaseModel, Field


class TrendSummaryResponse(BaseModel):
    anonymous_user_id: str = Field(..., alias="anonymousUserId")
    avg_speed: float = Field(..., alias="avgSpeed")
    fast_meal_count: int = Field(..., alias="fastMealCount")
    improvement_rate: float = Field(..., alias="improvementRate")
    summary_text: str = Field(..., alias="summaryText")
    ai_summary_text: str | None = Field(default=None, alias="aiSummaryText")
    window_days: int = Field(default=7, alias="windowDays")
    source: str = "ruleOnly"

    model_config = {"populate_by_name": True}
