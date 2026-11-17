"""Tests that need no database. DATABASE_URL is a dummy; the engine connects lazily."""

import os
import uuid

os.environ.setdefault("DATABASE_URL", "postgresql+asyncpg://user:password@localhost:5432/test")

import pytest
from fastapi.testclient import TestClient
from pydantic import ValidationError

from app.main import app
from app.schemas import CheckInRequest


def test_health():
    # No `with` block, so the lifespan (and its background loop) never starts.
    client = TestClient(app)
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_checkin_rejects_unknown_exercise_type():
    client = TestClient(app)
    response = client.post("/checkin", json={"device_id": str(uuid.uuid4()), "exercise_type": "yoga"})
    assert response.status_code == 422


def test_checkin_rejects_bad_device_id():
    client = TestClient(app)
    response = client.post("/checkin", json={"device_id": "not-a-uuid", "exercise_type": "chest"})
    assert response.status_code == 422


def test_schema_accepts_every_exercise_type():
    for exercise in ["chest", "back", "legs", "arms", "cardio"]:
        CheckInRequest(device_id=uuid.uuid4(), exercise_type=exercise)


def test_schema_requires_exercise_type():
    with pytest.raises(ValidationError):
        CheckInRequest(device_id=uuid.uuid4())
