# events_processor.py

import logging
from datetime import datetime
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from models import Event, PlayerIP

# Set up a logger to write to ip_changes.log
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
file_handler = logging.FileHandler("ip_changes.log")
logger.addHandler(file_handler)

def process_incoming_event(db: Session, event_data: dict) -> Event:
    event_type = event_data.get("event_type", "")
    group = event_data.get("group", "default")
    timestamp_str = event_data.get("timestamp")
    killer = event_data.get("killer")
    victim = event_data.get("victim")
    player = event_data.get("player")
    vehicle = event_data.get("vehicle")
    zone = event_data.get("zone")
    # 1) Extract IP address from event_data (or a different source).
    ip_address = event_data.get("ip_address")  # or "ip", or however your events store it

    # Convert timestamp
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
        group=group,
        raw_data=event_data
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

    # 2) After storing the Event, update or create the player's IP record
    if player and ip_address:
        _update_player_ip(db, player, ip_address, timestamp)

    return new_event

def _update_player_ip(db: Session, player: str, ip_address: str, timestamp: datetime):
    """
    Checks if this player’s IP has changed. If so, log it and update.
    """
    record = db.query(PlayerIP).filter_by(player=player).first()

    # If no record for player, create one
    if not record:
        record = PlayerIP(player=player, ip_address=ip_address, last_seen=timestamp)
        db.add(record)
        db.commit()
    else:
        # If IP changed, log and update
        if record.ip_address != ip_address:
            old_ip = record.ip_address
            record.ip_address = ip_address
            logger.info(f"{datetime.now()} | Player '{player}' IP changed from {old_ip} to {ip_address}")
        # Always update last_seen
        record.last_seen = timestamp
        db.commit()
