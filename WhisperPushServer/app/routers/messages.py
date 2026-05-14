import hashlib

from fastapi import APIRouter, Depends, HTTPException, Header, Query
from sqlalchemy import desc, select
from sqlalchemy.orm import Session

from app import models, schemas
from app.database import get_db
from app.dependencies import get_current_user

router = APIRouter()


def get_user_by_secret(db: Session, secret_key: str) -> models.User:
    """
    通过秘钥获取用户
    
    使用 SHA256 哈希验证秘钥，并返回关联的用户对象。
    
    Args:
        db: 数据库会话
        secret_key: 原始秘钥字符串
    
    Returns:
        models.User: 关联的用户对象，如果秘钥无效则返回 None
    """
    secret_key_hash = hashlib.sha256(secret_key.encode()).hexdigest()
    result = db.execute(
        select(models.Secret).where(
            models.Secret.secret_key_hash == secret_key_hash,
            models.Secret.is_active == True
        )
    )
    secret = result.scalars().first()

    if not secret:
        return None

    result = db.execute(
        select(models.User).where(models.User.id == secret.user_id)
    )
    return result.scalars().first()


def message_to_dict(message: models.Message) -> dict:
    """
    将消息对象转换为字典
    
    Args:
        message: 消息数据库模型对象
    
    Returns:
        dict: 包含消息所有字段的字典
    """
    return {
        "id": message.id,
        "user_id": message.user_id,
        "title": message.title,
        "body": message.body,
        "content_type": message.content_type,
        "group": message.group,
        "level": message.level,
        "created_at": message.created_at.isoformat() if message.created_at else None,
        "read": message.read
    }


@router.post("/push")
def push_message(
    message_data: schemas.PushMessageRequest,
    x_secret_key: str = Header(None),
    db: Session = Depends(get_db)
):
    """
    推送消息接口
    
    通过秘钥验证后向指定用户推送消息，并尝试通过 WebSocket 和推送服务通知用户。
    
    Args:
        message_data: 消息数据，包含 title、body、content_type、group、level
        x_secret_key: 请求头中的秘钥
        db: 数据库会话
    
    Returns:
        dict: 包含状态和消息ID的响应
    
    Raises:
        HTTPException: 401 - 秘钥缺失或无效
    """
    if not x_secret_key:
        raise HTTPException(status_code=401, detail="Secret key required")

    user = get_user_by_secret(db, x_secret_key)
    if not user:
        raise HTTPException(status_code=401, detail="Invalid secret key")

    new_message = models.Message(
        user_id=user.id,
        title=message_data.title,
        body=message_data.body,
        content_type=message_data.content_type,
        group=message_data.group,
        level=message_data.level
    )
    db.add(new_message)
    db.commit()
    db.refresh(new_message)

    message_dict = message_to_dict(new_message)

    # 尝试通过 WebSocket 推送
    try:
        from app.websocket import manager
        import asyncio
        asyncio.create_task(manager.send_new_message(user.id, message_dict))
    except Exception:
        pass

    # 获取用户活跃设备列表
    result = db.execute(
        select(models.Device).where(
            models.Device.user_id == user.id,
            models.Device.is_active == True,
            models.Device.device_token != None
        )
    )
    devices = result.scalars().all()

    # 尝试通过推送服务发送通知
    if devices:
        try:
            from app.push_service import push_service
            push_data = {
                "message_id": str(new_message.id),
                "content_type": new_message.content_type or "text",
            }
            if new_message.group:
                push_data["group"] = new_message.group
            if new_message.level:
                push_data["level"] = new_message.level

            push_service.send_push_to_user_devices(
                devices, new_message.title, new_message.body, push_data
            )
        except Exception:
            pass

    return {"status": "success", "message_id": new_message.id}


@router.get("/messages", response_model=list[schemas.MessageResponse])
def get_messages(
    skip: int = Query(0),
    limit: int = Query(100),
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """
    获取消息列表接口
    
    获取当前用户的消息列表，支持分页。
    
    Args:
        skip: 跳过的记录数，用于分页
        limit: 返回的最大记录数，默认100
        db: 数据库会话
        current_user: 当前已认证的用户对象
    
    Returns:
        list[schemas.MessageResponse]: 消息列表
    """
    result = db.execute(
        select(models.Message)
        .where(models.Message.user_id == current_user.id)
        .order_by(desc(models.Message.created_at))
        .offset(skip)
        .limit(limit)
    )
    return result.scalars().all()


@router.get("/messages/{msg_id}", response_model=schemas.MessageResponse)
def get_message(
    msg_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """
    获取单条消息接口
    
    获取指定ID的消息详情。
    
    Args:
        msg_id: 消息ID
        db: 数据库会话
        current_user: 当前已认证的用户对象
    
    Returns:
        schemas.MessageResponse: 消息详情
    
    Raises:
        HTTPException: 404 - 消息不存在或无权访问
    """
    result = db.execute(
        select(models.Message).where(
            models.Message.id == msg_id,
            models.Message.user_id == current_user.id
        )
    )
    message = result.scalars().first()

    if not message:
        raise HTTPException(status_code=404, detail="Message not found")

    return message


@router.patch("/messages/{msg_id}/read", response_model=schemas.MessageResponse)
def mark_message_read(
    msg_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """
    标记消息为已读接口
    
    将指定消息标记为已读状态。
    
    Args:
        msg_id: 消息ID
        db: 数据库会话
        current_user: 当前已认证的用户对象
    
    Returns:
        schemas.MessageResponse: 更新后的消息
    
    Raises:
        HTTPException: 404 - 消息不存在或无权访问
    """
    result = db.execute(
        select(models.Message).where(
            models.Message.id == msg_id,
            models.Message.user_id == current_user.id
        )
    )
    message = result.scalars().first()

    if not message:
        raise HTTPException(status_code=404, detail="Message not found")

    message.read = True
    db.commit()
    db.refresh(message)

    return message


@router.patch("/messages/{msg_id}/unread", response_model=schemas.MessageResponse)
def mark_message_unread(
    msg_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """
    标记消息为未读接口
    
    将指定消息标记为未读状态。
    
    Args:
        msg_id: 消息ID
        db: 数据库会话
        current_user: 当前已认证的用户对象
    
    Returns:
        schemas.MessageResponse: 更新后的消息
    
    Raises:
        HTTPException: 404 - 消息不存在或无权访问
    """
    result = db.execute(
        select(models.Message).where(
            models.Message.id == msg_id,
            models.Message.user_id == current_user.id
        )
    )
    message = result.scalars().first()

    if not message:
        raise HTTPException(status_code=404, detail="Message not found")

    message.read = False
    db.commit()
    db.refresh(message)

    return message


@router.delete("/messages/{msg_id}", status_code=204)
def delete_message(
    msg_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """
    删除消息接口
    
    删除指定消息。
    
    Args:
        msg_id: 消息ID
        db: 数据库会话
        current_user: 当前已认证的用户对象
    
    Returns:
        None: 204 状态码，无返回内容
    
    Raises:
        HTTPException: 404 - 消息不存在或无权访问
    """
    result = db.execute(
        select(models.Message).where(
            models.Message.id == msg_id,
            models.Message.user_id == current_user.id
        )
    )
    message = result.scalars().first()

    if not message:
        raise HTTPException(status_code=404, detail="Message not found")

    db.delete(message)
    db.commit()
    return None