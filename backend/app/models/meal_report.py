from datetime import datetime
from uuid import uuid4

from sqlalchemy import DateTime, ForeignKey, JSON, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class MealReport(Base):
    __tablename__ = "meal_reports"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid4()))
    meal_session_id: Mapped[str] = mapped_column(ForeignKey("meal_sessions.id"), unique=True, index=True)
    summary_text: Mapped[str] = mapped_column(Text)
    ai_summary_text: Mapped[str | None] = mapped_column(Text, nullable=True)
    suggestions: Mapped[list] = mapped_column(JSON, default=list)
    generated_by: Mapped[str] = mapped_column(String(32), default="ruleOnly")
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=datetime.utcnow,
        onupdate=datetime.utcnow,
    )

    meal_session = relationship("MealSession", back_populates="report")
