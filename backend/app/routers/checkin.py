import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.exc import IntegrityError

from app.database import get_db
from app.limiter import limiter
from app.models import Visit
from app.schemas import CheckInRequest, VisitResponse

router = APIRouter(tags=["visits"])


@router.post("/checkin", response_model=VisitResponse, status_code=status.HTTP_201_CREATED)
@limiter.limit("10/minute")
async def check_in(request: Request, body: CheckInRequest, db: AsyncSession = Depends(get_db)):
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
