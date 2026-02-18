from fastapi import APIRouter, Depends, Request
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.limiter import limiter
from app.models import Visit
from app.schemas import OccupancyResponse

router = APIRouter(tags=["occupancy"])


@router.get("/occupancy", response_model=OccupancyResponse)
@limiter.limit("30/minute")
async def get_occupancy(request: Request, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(func.count(Visit.id)).where(Visit.check_out_time.is_(None))
    )
    count = result.scalar_one()
    return OccupancyResponse(count=count)
