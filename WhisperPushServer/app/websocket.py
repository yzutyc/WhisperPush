from typing import Dict, Set

from fastapi import WebSocket, WebSocketDisconnect


class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[int, Set[WebSocket]] = {}

    async def connect(self, user_id: int, websocket: WebSocket):
        await websocket.accept()
        if user_id not in self.active_connections:
            self.active_connections[user_id] = set()
        self.active_connections[user_id].add(websocket)

    def disconnect(self, user_id: int, websocket: WebSocket):
        if user_id in self.active_connections:
            self.active_connections[user_id].discard(websocket)
            if not self.active_connections[user_id]:
                del self.active_connections[user_id]

    async def send_personal_message(self, user_id: int, message: dict):
        if user_id in self.active_connections:
            disconnected_websockets = set()
            for websocket in self.active_connections[user_id]:
                try:
                    await websocket.send_json(message)
                except (WebSocketDisconnect, RuntimeError):
                    disconnected_websockets.add(websocket)

            for websocket in disconnected_websockets:
                self.disconnect(user_id, websocket)

    async def send_new_message(self, user_id: int, message: dict):
        ws_message = {
            "type": "new_message",
            "data": message
        }
        await self.send_personal_message(user_id, ws_message)

    def is_user_online(self, user_id: int) -> bool:
        return user_id in self.active_connections and len(self.active_connections[user_id]) > 0

manager = ConnectionManager()
