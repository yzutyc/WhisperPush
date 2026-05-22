from fastapi import APIRouter, Depends, HTTPException, WebSocket, WebSocketDisconnect
from jose import JWTError, jwt
from sqlalchemy import desc, select
from sqlalchemy.orm import Session

from app import models, schemas
from app.config import settings
from app.database import get_db
from app.dependencies import get_current_user
from app.websocket import manager

router = APIRouter()


def get_current_user_from_token(token: str, db: Session) -> models.User:
    """
    从 JWT 令牌获取用户
    
    解析 JWT 令牌并返回对应的用户对象，用于 WebSocket 认证。
    
    Args:
        token: JWT 访问令牌
        db: 数据库会话
    
    Returns:
        models.User: 认证后的用户对象
    
    Raises:
        HTTPException: 401 - 令牌无效或用户不存在
    """
    credentials_exception = HTTPException(
        status_code=401,
        detail="Could not validate credentials",
    )
    try:
        payload = jwt.decode(token, settings.secret_key, algorithms=[settings.algorithm])
        user_id_str = payload.get("sub")
        if user_id_str is None:
            raise credentials_exception
        user_id = int(user_id_str)
    except (JWTError, ValueError):
        raise credentials_exception
    except Exception as e:
        raise Exception(e)

    result = db.execute(select(models.User).where(models.User.id == user_id))
    user = result.scalars().first()
    if user is None:
        raise credentials_exception
    return user


@router.post("/devices", response_model=schemas.DeviceResponse)
def register_device(
    device: schemas.DeviceCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """
    注册设备接口
    
    为当前用户注册新的推送设备（Android/iOS）。
    
    Args:
        device: 设备信息，包含 device_type、device_token、device_name
        db: 数据库会话
        current_user: 当前已认证的用户对象
    
    Returns:
        schemas.DeviceResponse: 注册后的设备信息
    """
    new_device = models.Device(
        user_id=current_user.id,
        device_type=device.device_type,
        device_token=device.device_token,
        device_name=device.device_name,
        push_vendor=device.push_vendor
    )
    db.add(new_device)
    db.commit()
    db.refresh(new_device)
    return new_device


@router.get("/devices", response_model=list[schemas.DeviceResponse])
def list_devices(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """
    获取设备列表接口
    
    获取当前用户的所有注册设备。
    
    Args:
        db: 数据库会话
        current_user: 当前已认证的用户对象
    
    Returns:
        list[schemas.DeviceResponse]: 设备列表
    """
    result = db.execute(
        select(models.Device)
        .where(models.Device.user_id == current_user.id)
        .order_by(desc(models.Device.created_at))
    )
    return result.scalars().all()


@router.delete("/devices/{device_id}")
def delete_device(
    device_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """
    删除设备接口
    
    删除指定的注册设备。
    
    Args:
        device_id: 设备ID
        db: 数据库会话
        current_user: 当前已认证的用户对象
    
    Returns:
        dict: 包含状态的响应
    
    Raises:
        HTTPException: 404 - 设备不存在或无权访问
    """
    result = db.execute(
        select(models.Device).where(
            models.Device.id == device_id,
            models.Device.user_id == current_user.id
        )
    )
    device = result.scalars().first()

    if not device:
        raise HTTPException(status_code=404, detail="Device not found")

    db.delete(device)
    db.commit()
    return {"status": "success"}


@router.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket, token: str, db: Session = Depends(get_db)):
    """
    WebSocket 连接端点
    
    建立实时消息推送连接，客户端需要提供有效的 JWT 令牌进行认证。
    
    Args:
        websocket: WebSocket 连接对象
        token: JWT 访问令牌
        db: 数据库会话
    """
    try:
        user = get_current_user_from_token(token, db)
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