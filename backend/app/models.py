import uuid
from datetime import datetime
from sqlalchemy import UUID, TIMESTAMP, Text, text
from sqlalchemy.orm import Mapped, mapped_column
from app.database import Base


class Visit(Base):
    __tablename__ = "visits"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    device_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), nullable=False)
    check_in_time: Mapped[datetime] = mapped_column(
        TIMESTAMP(timezone=True), nullable=False, server_default=text("NOW()")
    )
    check_out_time: Mapped[datetime | None] = mapped_column(
        TIMESTAMP(timezone=True), nullable=True
    )
    exercise_type: Mapped[str | None] = mapped_column(Text, nullable=True)
