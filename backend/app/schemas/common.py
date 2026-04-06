from pydantic import BaseModel, Field


class QuietHours(BaseModel):
    enabled: bool = True
    start: str = Field(default="22:00")
    end: str = Field(default="07:00")
