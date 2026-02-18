from fastapi import APIRouter, Depends
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models import Visit
from app.schemas import OccupancyResponse

router = APIRouter(tags=["occupancy"])


@router.get(
    "/occupancy",
    response_model=OccupancyResponse,
    summary="Get current gym occupancy",
)
async def get_occupancy(db: AsyncSession = Depends(get_db)):
    """
    Returns the number of devices currently checked in (active visits).

    Uses the partial index on (check_out_time IS NULL) for an efficient count.
    """
    result = await db.execute(
        select(func.count(Visit.id)).where(Visit.check_out_time.is_(None))
    )
    count = result.scalar_one()
    return OccupancyResponse(count=count)
