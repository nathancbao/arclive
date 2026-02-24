from fastapi import APIRouter, Depends, Request
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.limiter import limiter
from app.models import Visit
from app.schemas import ExerciseBreakdown, OccupancyResponse

router = APIRouter(tags=["occupancy"])

EXERCISES = ["chest", "back", "legs", "arms", "cardio"]


@router.get("/occupancy", response_model=OccupancyResponse)
@limiter.limit("30/minute")
async def get_occupancy(request: Request, db: AsyncSession = Depends(get_db)):
    # Total active count
    total_result = await db.execute(
        select(func.count(Visit.id)).where(Visit.check_out_time.is_(None))
    )
    total = total_result.scalar_one()

    # Per-exercise breakdown
    breakdown_result = await db.execute(
        select(Visit.exercise_type, func.count(Visit.id))
        .where(Visit.check_out_time.is_(None))
        .group_by(Visit.exercise_type)
    )
    counts = {row[0]: row[1] for row in breakdown_result.all()}

    breakdown = ExerciseBreakdown(
        chest=counts.get("chest", 0),
        back=counts.get("back", 0),
        legs=counts.get("legs", 0),
        arms=counts.get("arms", 0),
        cardio=counts.get("cardio", 0),
    )

    return OccupancyResponse(count=total, breakdown=breakdown)
