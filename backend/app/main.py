import asyncio
from contextlib import asynccontextmanager
from datetime import datetime, timezone, timedelta

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from slowapi.errors import RateLimitExceeded
from slowapi import _rate_limit_exceeded_handler

from app.limiter import limiter
from app.database import AsyncSessionLocal
from app.models import Visit
from app.routers import checkin, checkout, occupancy, stats
from sqlalchemy import select


async def auto_checkout_loop():
    """Every 30 min, close any visit open longer than 4 hours."""
    while True:
        await asyncio.sleep(30 * 60)
        try:
            cutoff = datetime.now(timezone.utc) - timedelta(hours=4)
            async with AsyncSessionLocal() as db:
                result = await db.execute(
                    select(Visit).where(
                        Visit.check_out_time.is_(None),
                        Visit.check_in_time < cutoff,
                    )
                )
                stale = result.scalars().all()
                for visit in stale:
                    visit.check_out_time = datetime.now(timezone.utc)
                if stale:
                    await db.commit()
        except Exception:
            pass  # never crash the loop


@asynccontextmanager
async def lifespan(app: FastAPI):
    task = asyncio.create_task(auto_checkout_loop())
    yield
    task.cancel()


app = FastAPI(
    title="ArcLive Gym Occupancy API",
    version="1.0.0",
    description="Device-based check-in / check-out tracking for gym occupancy.",
    lifespan=lifespan,
)

app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)

app.include_router(checkin.router)
app.include_router(checkout.router)
app.include_router(occupancy.router)
app.include_router(stats.router)


@app.get("/health", tags=["meta"])
async def health():
    return {"status": "ok"}
