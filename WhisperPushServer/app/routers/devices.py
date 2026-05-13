from fastapi import APIRouter, Depends, HTTPException, WebSocket, WebSocketDisconnect
from jose import JWTError, jwt
from sqlalchemy import desc
from sqlalchemy.ext.asyncio import AsyncSession

from app import models, schemas
from app.config import settings
from app.database import get_db
from app.dependencies import get_current_user
from app.websocket import manager

router = APIRouter()

async def get_current_user_from_token(token: str, db: AsyncSession) -> models.User:
    credentials_exception = HTTPException(
        status_code=401,
        detail="Could not validate credentials",
    )
    try:
        payload = jwt.decode(token, settings.secret_key, algorithms=[settings.algorithm])
        user_id: int = payload.get("sub")
        if user_id is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception

    result = await db.execute(models.User.__table__.select().where(models.User.id == user_id))
    user = result.scalars().first()
    if user is None:
        raise credentials_exception
    return user

@router.post("/devices", response_model=schemas.DeviceResponse)
async def register_device(
    device: schemas.DeviceCreate,
    db: AsyncSession = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    new_device = models.Device(
        user_id=current_user.id,
        device_type=device.device_type,
        device_token=device.device_token,
        device_name=device.device_name
    )
    db.add(new_device)
    await db.commit()
    await db.refresh(new_device)
    return new_device

@router.get("/devices", response_model=list[schemas.DeviceResponse])
async def list_devices(
    db: AsyncSession = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    result = await db.execute(
        models.Device.__table__.select()
        .where(models.Device.user_id == current_user.id)
        .order_by(desc(models.Device.created_at))
    )
    return result.scalars().all()

@router.delete("/devices/{device_id}")
async def delete_device(
    device_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    result = await db.execute(
        models.Device.__table__.select().where(
            models.Device.id == device_id,
            models.Device.user_id == current_user.id
        )
    )
    device = result.scalars().first()

    if not device:
        raise HTTPException(status_code=404, detail="Device not found")

    await db.execute(models.Device.__table__.delete().where(models.Device.id == device_id))
    await db.commit()
    return {"status": "success"}

@router.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket, token: str, db: AsyncSession = Depends(get_db)):
    try:
        user = await get_current_user_from_token(token, db)
    except HTTPException:
        await websocket.close(code=1008)
        return

    await manager.connect(user.id, websocket)
    try:
        while True:
            data = await websocket.receive_text()
            await websocket.send_json({"type": "pong", "data": data})
    except WebSocketDisconnect:
        manager.disconnect(user.id, websocket)
