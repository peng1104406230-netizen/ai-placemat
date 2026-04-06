from contextlib import asynccontextmanager

from fastapi import FastAPI

from app.api.router import api_router
from app.db.base import Base
from app.db.session import engine
from app.models import MealReport, MealSession, TrendSnapshot, User, UserSettings


@asynccontextmanager
async def lifespan(_: FastAPI):
    _ = (User, UserSettings, MealSession, MealReport, TrendSnapshot)
    Base.metadata.create_all(bind=engine)
    yield


def create_app() -> FastAPI:
    app = FastAPI(
        title="AI Placemat Backend",
        version="0.1.0",
        description=(
            "Minimal backend scaffold for settings, meal, report, and trend. "
            "AI summaries use BackgroundTasks and stub graph implementations."
        ),
        lifespan=lifespan,
    )
    app.include_router(api_router)
    return app


app = create_app()
