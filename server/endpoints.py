"""
Defines FastAPI endpoints for receiving events (/event) and WebSocket connections (/ws).
"""
from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from typing import Any, Dict
from sqlalchemy.orm import Session

from database import SessionLocal
from events_processor import process_incoming_event
from websocket_friend import ConnectionManager

router = APIRouter()
ws_manager = ConnectionManager()

@router.post("/event")
async def post_event(data: Dict[str, Any]):
    db: Session = SessionLocal()
    try:
        event = process_incoming_event(db, data)
    finally:
        db.close()

    event_dict = {
        "event_type": event.event_type,
        "timestamp": event.timestamp.isoformat(),
        "player": event.player,
        "killer": event.killer,
        "victim": event.victim,
        "vehicle": event.vehicle,
        "zone": event.zone,
        "group": event.group
    }

    # Broadcast to WebSocket subscribers
    await ws_manager.send_event_to_subscribers(event_dict)

    # If you want to notify the discord bot for each event, import and call notify function:
    # from app import notify_discord_bot
    # notify_discord_bot(event_dict)

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
