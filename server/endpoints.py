from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Request
from typing import Any, Dict
from sqlalchemy.orm import Session

from database import SessionLocal
from events_processor import process_incoming_event
from websocket_friend import ConnectionManager

# If you want to notify the Discord bot directly:
from app import notify_discord_bot

router = APIRouter()
ws_manager = ConnectionManager()

@router.post("/event")
async def post_event(request: Request, data: Dict[str, Any]):
    client_ip = request.client.host
    data["ip_address"] = client_ip

    db: Session = SessionLocal()
    try:
        event = process_incoming_event(db, data)
    finally:
        db.close()

    # event.raw_data holds *all* attributes from slog.ps1.
    # We make a copy to avoid mutating the original.
    event_dict = dict(event.raw_data or {})

    # Override or set top-level fields to keep them consistent:
    event_dict.update({
        "event_type": event.event_type,
        "timestamp": event.timestamp.isoformat(),
        "group": event.group,
        "player": event.player,
        "killer": event.killer,
        "victim": event.victim,
        "vehicle": event.vehicle,
        "zone": event.zone,
    })

    # Broadcast to WebSocket subscribers
    await ws_manager.send_event_to_subscribers(event_dict)

    # Notify the Discord bot as well (if desired):
    notify_discord_bot(event_dict)

    return {"status": "ok"}

@router.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await ws_manager.connect(websocket)
    try:
        while True:
            data = await websocket.receive_json()
            action = data.get("action")
            if action == "subscribe":
                group = data.get("group")
                ws_manager.subscribe(websocket, group)
    except WebSocketDisconnect:
        ws_manager.disconnect(websocket)
