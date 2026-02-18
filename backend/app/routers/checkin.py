import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.exc import IntegrityError

from app.database import get_db
from app.models import Visit
from app.schemas import CheckInRequest, VisitResponse

router = APIRouter(tags=["visits"])


@router.post(
    "/checkin",
    response_model=VisitResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Check a device in",
)
async def check_in(body: CheckInRequest, db: AsyncSession = Depends(get_db)):
    """
    Creates a new active visit for the given device_id.

    - **201 Created** — visit opened successfully.
    - **409 Conflict** — device already has an active visit (partial unique index violation).

    Concurrency: the partial unique index on (device_id) WHERE check_out_time IS NULL
    is enforced at the database level, so simultaneous duplicate requests from the same
    device are safely rejected even under high load.
    """
    visit = Visit(
        id=uuid.uuid4(),
        device_id=body.device_id,
        check_in_time=datetime.now(timezone.utc),
    )
    db.add(visit)
    try:
        await db.commit()
        await db.refresh(visit)
    except IntegrityError:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Device is already checked in.",
        )
    return visit
