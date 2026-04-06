from fastapi import APIRouter

from app.api.routes import meal, report, settings, trend

api_router = APIRouter()
api_router.include_router(settings.router, prefix="/settings", tags=["settings"])
api_router.include_router(meal.router, prefix="/meal", tags=["meal"])
api_router.include_router(report.router, prefix="/report", tags=["report"])
api_router.include_router(trend.router, prefix="/trend", tags=["trend"])
