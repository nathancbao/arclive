import uuid
from datetime import datetime
from typing import Literal
from pydantic import BaseModel

ExerciseType = Literal["chest", "back", "legs", "arms", "cardio"]


class CheckInRequest(BaseModel):
    device_id: uuid.UUID
    exercise_type: ExerciseType


class CheckOutRequest(BaseModel):
    device_id: uuid.UUID


class VisitResponse(BaseModel):
    id: uuid.UUID
    device_id: uuid.UUID
    check_in_time: datetime
    check_out_time: datetime | None
    exercise_type: str | None

    model_config = {"from_attributes": True}


class ExerciseBreakdown(BaseModel):
    chest: int = 0
    back: int = 0
    legs: int = 0
    arms: int = 0
    cardio: int = 0


class OccupancyResponse(BaseModel):
    count: int
    breakdown: ExerciseBreakdown
