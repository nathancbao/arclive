import uuid
from datetime import datetime
from pydantic import BaseModel


class CheckInRequest(BaseModel):
    device_id: uuid.UUID


class CheckOutRequest(BaseModel):
    device_id: uuid.UUID


class VisitResponse(BaseModel):
    id: uuid.UUID
    device_id: uuid.UUID
    check_in_time: datetime
    check_out_time: datetime | None

    model_config = {"from_attributes": True}


class OccupancyResponse(BaseModel):
    count: int
