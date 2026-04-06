from datetime import datetime
from uuid import uuid4

from sqlalchemy import DateTime, Float, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class TrendSnapshot(Base):
    __tablename__ = "trend_snapshots"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid4()))
    user_id: Mapped[str] = mapped_column(ForeignKey("users.id"), index=True)
    window_days: Mapped[int] = mapped_column(Integer, default=7)
    avg_speed: Mapped[float] = mapped_column(Float)
    fast_meal_count: Mapped[int] = mapped_column(Integer)
    improvement_rate: Mapped[float] = mapped_column(Float)
    summary_text: Mapped[str] = mapped_column(Text)
    ai_summary_text: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)

    user = relationship("User", back_populates="trend_snapshots")
