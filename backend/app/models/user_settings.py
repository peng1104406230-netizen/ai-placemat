from datetime import datetime
from uuid import uuid4

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, JSON, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class UserSettings(Base):
    __tablename__ = "user_settings"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid4()))
    user_id: Mapped[str] = mapped_column(ForeignKey("users.id"), unique=True, index=True)
    reminder_enabled: Mapped[bool] = mapped_column(Boolean, default=True)
    reminder_frequency: Mapped[int] = mapped_column(Integer, default=180)
    reminder_text: Mapped[str] = mapped_column(
        String(255),
        default="慢一点吃，今天也在认真照顾自己。",
    )
    voice_enabled: Mapped[bool] = mapped_column(Boolean, default=True)
    quiet_hours: Mapped[dict] = mapped_column(JSON, default=lambda: {"enabled": True, "start": "22:00", "end": "07:00"})
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=datetime.utcnow,
        onupdate=datetime.utcnow,
    )

    user = relationship("User", back_populates="settings")
