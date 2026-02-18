from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from slowapi.errors import RateLimitExceeded
from slowapi import _rate_limit_exceeded_handler
from app.limiter import limiter
from app.routers import checkin, checkout, occupancy

app = FastAPI(
    title="ArcLive Gym Occupancy API",
    version="1.0.0",
    description="Device-based check-in / check-out tracking for gym occupancy.",
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


@app.get("/health", tags=["meta"])
async def health():
    return {"status": "ok"}
