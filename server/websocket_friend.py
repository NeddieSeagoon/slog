"""
Manages WebSocket connections and subscriptions by group.
"""
from fastapi import WebSocket

class ConnectionManager:
    def __init__(self):
        self.active_connections = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append({"websocket": websocket, "group": None})

    def disconnect(self, websocket: WebSocket):
        self.active_connections = [
            c for c in self.active_connections if c["websocket"] != websocket
        ]

    def subscribe(self, websocket: WebSocket, group: str):
        for c in self.active_connections:
            if c["websocket"] == websocket:
                c["group"] = group

    async def send_event_to_subscribers(self, event_data: dict):
        event_group = event_data.get("group")
        for c in self.active_connections:
            if c["group"] == event_group and event_group is not None:
                await c["websocket"].send_json(event_data)
