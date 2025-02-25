# models.py
from sqlalchemy.orm import declarative_base
from sqlalchemy import Column, Integer, String, DateTime, UniqueConstraint, JSON

Base = declarative_base()

class Event(Base):
    __tablename__ = "events"

    id = Column(Integer, primary_key=True, index=True)
    event_type = Column(String, index=True)
    timestamp = Column(DateTime, index=True)
    player = Column(String, nullable=True)
    killer = Column(String, nullable=True)
    victim = Column(String, nullable=True)
    vehicle = Column(String, nullable=True)
    zone = Column(String, nullable=True)
    group = Column(String, index=True)

    # Store the raw event payload as JSON
    raw_data = Column(JSON, nullable=True)

    __table_args__ = (
        UniqueConstraint("event_type", "timestamp", "group", name="uq_event_type_timestamp_group"),
    )
