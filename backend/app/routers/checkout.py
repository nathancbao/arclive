from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models import Visit
from app.schemas import CheckOutRequest, VisitResponse

router = APIRouter(tags=["visits"])


@router.post(
    "/checkout",
    response_model=VisitResponse,
    summary="Check a device out",
)
async def check_out(body: CheckOutRequest, db: AsyncSession = Depends(get_db)):
    """
    Closes the active visit for the given device_id by setting check_out_time.

    - **200 OK** — visit closed successfully.
    - **404 Not Found** — no active visit exists for this device.

    Concurrency: SELECT ... FOR UPDATE acquires a row-level lock before writing,
    preventing two simultaneous checkout requests from racing.
    """
    result = await db.execute(
        select(Visit)
        .where(
            Visit.device_id == body.device_id,
            Visit.check_out_time.is_(None),
        )
        .with_for_update()  # row-level lock for safe concurrent updates
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
