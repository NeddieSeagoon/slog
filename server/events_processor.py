"""
Processes incoming events, performs deduplication, and returns the saved/ existing Event.
"""
from datetime import datetime
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from models import Event

def process_incoming_event(db: Session, event_data: dict) -> Event:
    event_type = event_data.get("event_type", "")
    group = event_data.get("group", "default")
    timestamp_str = event_data.get("timestamp")
    killer = event_data.get("killer")
    victim = event_data.get("victim")
    player = event_data.get("player")
    vehicle = event_data.get("vehicle")
    zone = event_data.get("zone")

    try:
        timestamp = datetime.fromisoformat(timestamp_str)
    except (ValueError, TypeError):
        timestamp = datetime.utcnow()

    new_event = Event(
        event_type=event_type,
        timestamp=timestamp,
        killer=killer,
        victim=victim,
        player=player,
        vehicle=vehicle,
        zone=zone,
        group=group
    )

    db.add(new_event)
    try:
        db.commit()
        db.refresh(new_event)
    except IntegrityError:
        db.rollback()
        existing = db.query(Event).filter_by(
            event_type=event_type,
            timestamp=timestamp,
            group=group
        ).first()
        if existing:
            return existing
        else:
            raise

    return new_event
