from datetime import datetime

from pydantic import BaseModel, Field


class MealSample(BaseModel):
    ts: datetime
    weight_gram: float = Field(..., alias="weightGram")

    model_config = {"populate_by_name": True}


class MealEvent(BaseModel):
    ts: datetime
    event_type: str = Field(..., alias="eventType")
    value: str | None = None

    model_config = {"populate_by_name": True}


class MealUploadRequest(BaseModel):
    anonymous_user_id: str = Field(..., alias="anonymousUserId")
    meal_id: str = Field(..., alias="mealId")
    start_time: datetime = Field(..., alias="startTime")
    end_time: datetime = Field(..., alias="endTime")
    duration_sec: int = Field(..., alias="durationSec")
    intake_grams: float = Field(..., alias="intakeGrams")
    avg_speed: float = Field(..., alias="avgSpeed")
    peak_speed: float = Field(..., alias="peakSpeed")
    reminder_count: int = Field(..., alias="reminderCount")
    samples: list[MealSample] = Field(default_factory=list)
    events: list[MealEvent] = Field(default_factory=list)

    model_config = {"populate_by_name": True}


class MealUploadResponse(BaseModel):
    anonymous_user_id: str = Field(..., alias="anonymousUserId")
    meal_id: str = Field(..., alias="mealId")
    status: str
    report_status: str = Field(..., alias="reportStatus")
    trend_status: str = Field(..., alias="trendStatus")

    model_config = {"populate_by_name": True}


class MealDetailResponse(MealUploadRequest):
    pass
