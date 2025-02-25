# models.py
from sqlalchemy.orm import declarative_base
from sqlalchemy import Column, Integer, String, DateTime, UniqueConstraint, JSON
from datetime import datetime

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
    raw_data = Column(JSON, nullable=True)

    __table_args__ = (
        UniqueConstraint("event_type", "timestamp", "group", name="uq_event_type_timestamp_group"),
    )

# NEW table to track player -> current IP and last seen time
class PlayerIP(Base):
    __tablename__ = "player_ips"

    id = Column(Integer, primary_key=True, index=True)
    player = Column(String, index=True, nullable=False)
    ip_address = Column(String, index=True, nullable=False)
    last_seen = Column(DateTime, default=datetime.utcnow)

    __table_args__ = (
        UniqueConstraint("player", name="uq_player_ips_player"),
    )
