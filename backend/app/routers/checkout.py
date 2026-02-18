from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.limiter import limiter
from app.models import Visit
from app.schemas import CheckOutRequest, VisitResponse

router = APIRouter(tags=["visits"])


@router.post("/checkout", response_model=VisitResponse)
@limiter.limit("10/minute")
async def check_out(request: Request, body: CheckOutRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(Visit)
        .where(
            Visit.device_id == body.device_id,
            Visit.check_out_time.is_(None),
        )
        .with_for_update()
    )
    visit = result.scalar_one_or_none()

    if visit is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No active visit found for this device.",
        )

    visit.check_out_time = datetime.now(timezone.utc)
    await db.commit()
    await db.refresh(visit)
    return visit
