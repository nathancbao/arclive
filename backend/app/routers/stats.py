import uuid
from datetime import datetime, timezone, timedelta, date

from fastapi import APIRouter, Depends, Query, Request
from sqlalchemy import func, select, text
from sqlalchemy.ext.asyncio import AsyncSession
from pydantic import BaseModel

from app.database import get_db
from app.limiter import limiter
from app.models import Visit
from app.schemas import ExerciseBreakdown

router = APIRouter(prefix="/stats", tags=["stats"])


# ─── Response schemas ────────────────────────────────────────────────────────

class HourlyCount(BaseModel):
    hour: int
    count: float  # daily average over the past 30 days


class DailyCount(BaseModel):
    date: str   # ISO date string YYYY-MM-DD
    count: int


class GymStatsResponse(BaseModel):
    peak_hours: list[HourlyCount]
    daily_headcount: list[DailyCount]
    exercise_breakdown: ExerciseBreakdown


class VisitDetail(BaseModel):
    id: uuid.UUID
    check_in_time: datetime
    check_out_time: datetime | None
    exercise_type: str | None
    duration_minutes: int | None


class PersonalStatsResponse(BaseModel):
    total_visits: int
    total_minutes: int
    streak: int
    favourite_exercise: str | None
    recent_visits: list[VisitDetail]


# ─── Helpers ─────────────────────────────────────────────────────────────────

def _calculate_streak(dates: list[date]) -> int:
    if not dates:
        return 0
    today = datetime.now(timezone.utc).date()
    if dates[0] < today - timedelta(days=1):
        return 0
    streak, expected = 0, dates[0]
    for d in dates:
        if d == expected:
            streak += 1
            expected = d - timedelta(days=1)
        else:
            break
    return streak


# ─── Endpoints ───────────────────────────────────────────────────────────────

@router.get("/gym", response_model=GymStatsResponse)
@limiter.limit("30/minute")
async def gym_stats(request: Request, db: AsyncSession = Depends(get_db)):
    now = datetime.now(timezone.utc)
    thirty_days_ago = now - timedelta(days=30)
    seven_days_ago  = now - timedelta(days=7)

    # Peak hours — total check-ins per hour over past 30 days, averaged per day
    hour_result = await db.execute(
        select(
            func.extract("hour", Visit.check_in_time).label("hour"),
            func.count(Visit.id).label("count"),
        )
        .where(Visit.check_in_time > thirty_days_ago)
        .group_by(func.extract("hour", Visit.check_in_time))
        .order_by(func.extract("hour", Visit.check_in_time))
    )
    hour_rows = hour_result.all()
    peak_hours = [
        HourlyCount(hour=int(r.hour), count=round(r.count / 30, 1))
        for r in hour_rows
    ]

    # Daily headcount — unique devices per day for past 7 days
    daily_result = await db.execute(
        select(
            func.date(Visit.check_in_time).label("date"),
            func.count(Visit.device_id.distinct()).label("count"),
        )
        .where(Visit.check_in_time > seven_days_ago)
        .group_by(func.date(Visit.check_in_time))
        .order_by(func.date(Visit.check_in_time))
    )
    daily_headcount = [
        DailyCount(date=str(r.date), count=r.count)
        for r in daily_result.all()
    ]

    # Exercise breakdown — past 30 days
    ex_result = await db.execute(
        select(Visit.exercise_type, func.count(Visit.id))
        .where(
            Visit.check_in_time > thirty_days_ago,
            Visit.exercise_type.is_not(None),
        )
        .group_by(Visit.exercise_type)
    )
    ex_counts = {r[0]: r[1] for r in ex_result.all()}
    breakdown = ExerciseBreakdown(
        chest=ex_counts.get("chest", 0),
        back=ex_counts.get("back", 0),
        legs=ex_counts.get("legs", 0),
        arms=ex_counts.get("arms", 0),
        cardio=ex_counts.get("cardio", 0),
    )

    return GymStatsResponse(
        peak_hours=peak_hours,
        daily_headcount=daily_headcount,
        exercise_breakdown=breakdown,
    )


@router.get("/me", response_model=PersonalStatsResponse)
@limiter.limit("30/minute")
async def personal_stats(
    request: Request,
    device_id: uuid.UUID = Query(...),
    db: AsyncSession = Depends(get_db),
):
    # Total visits
    total_result = await db.execute(
        select(func.count(Visit.id)).where(Visit.device_id == device_id)
    )
    total_visits = total_result.scalar_one()

    # Total minutes (completed visits only)
    minutes_result = await db.execute(
        select(
            func.sum(
                func.extract("epoch", Visit.check_out_time - Visit.check_in_time) / 60
            )
        ).where(
            Visit.device_id == device_id,
            Visit.check_out_time.is_not(None),
        )
    )
    total_minutes = int(minutes_result.scalar_one() or 0)

    # Favourite exercise
    fav_result = await db.execute(
        select(Visit.exercise_type, func.count(Visit.id).label("cnt"))
        .where(
            Visit.device_id == device_id,
            Visit.exercise_type.is_not(None),
        )
        .group_by(Visit.exercise_type)
        .order_by(text("cnt DESC"))
        .limit(1)
    )
    fav_row = fav_result.first()
    favourite_exercise = fav_row[0] if fav_row else None

    # Streak — distinct visit days ordered desc
    dates_result = await db.execute(
        select(func.date(Visit.check_in_time).label("d"))
        .where(Visit.device_id == device_id)
        .group_by(func.date(Visit.check_in_time))
        .order_by(func.date(Visit.check_in_time).desc())
    )
    dates = [r.d for r in dates_result.all()]
    streak = _calculate_streak(dates)

    # Recent visits (last 20)
    visits_result = await db.execute(
        select(Visit)
        .where(Visit.device_id == device_id)
        .order_by(Visit.check_in_time.desc())
        .limit(20)
    )
    visits = visits_result.scalars().all()

    recent = []
    for v in visits:
        duration = None
        if v.check_out_time:
            duration = int((v.check_out_time - v.check_in_time).total_seconds() / 60)
        recent.append(VisitDetail(
            id=v.id,
            check_in_time=v.check_in_time,
            check_out_time=v.check_out_time,
            exercise_type=v.exercise_type,
            duration_minutes=duration,
        ))

    return PersonalStatsResponse(
        total_visits=total_visits,
        total_minutes=total_minutes,
        streak=streak,
        favourite_exercise=favourite_exercise,
        recent_visits=recent,
    )
