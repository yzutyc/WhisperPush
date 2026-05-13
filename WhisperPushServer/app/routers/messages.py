import asyncio
import hashlib

from fastapi import APIRouter, Depends, HTTPException, Header, Query
from sqlalchemy import desc
from sqlalchemy.ext.asyncio import AsyncSession

from app import models, schemas
from app.database import get_db
from app.dependencies import get_current_user
from app.push_service import push_service
from app.websocket import manager

router = APIRouter()

async def get_user_by_secret(db: AsyncSession, secret_key: str) -> models.User:
    secret_key_hash = hashlib.sha256(secret_key.encode()).hexdigest()
    result = await db.execute(
        models.Secret.__table__.select().where(
            models.Secret.secret_key_hash == secret_key_hash,
            models.Secret.is_active == True
        )
    )
    secret = result.scalars().first()

    if not secret:
        return None

    result = await db.execute(
        models.User.__table__.select().where(models.User.id == secret.user_id)
    )
    return result.scalars().first()

def message_to_dict(message: models.Message) -> dict:
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
async def push_message(
    message_data: schemas.PushMessageRequest,
    x_secret_key: str = Header(None),
    db: AsyncSession = Depends(get_db)
):
    if not x_secret_key:
        raise HTTPException(status_code=401, detail="Secret key required")

    user = await get_user_by_secret(db, x_secret_key)
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
    await db.commit()
    await db.refresh(new_message)

    message_dict = message_to_dict(new_message)

    await manager.send_new_message(user.id, message_dict)

    result = await db.execute(
        models.Device.__table__.select().where(
            models.Device.user_id == user.id,
            models.Device.is_active == True,
            models.Device.device_token != None
        )
    )
    devices = result.scalars().all()

    if devices:
        push_data = {
            "message_id": str(new_message.id),
            "content_type": new_message.content_type or "text",
        }
        if new_message.group:
            push_data["group"] = new_message.group
        if new_message.level:
            push_data["level"] = new_message.level

        asyncio.create_task(
            push_service.send_push_to_user_devices(
                devices, new_message.title, new_message.body, push_data
            )
        )

    return {"status": "success", "message_id": new_message.id}

@router.get("/messages", response_model=list[schemas.MessageResponse])
async def get_messages(
    skip: int = Query(0),
    limit: int = Query(100),
    db: AsyncSession = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    result = await db.execute(
        models.Message.__table__.select()
        .where(models.Message.user_id == current_user.id)
        .order_by(desc(models.Message.created_at))
        .offset(skip)
        .limit(limit)
    )
    return result.scalars().all()

@router.get("/messages/{msg_id}", response_model=schemas.MessageResponse)
async def get_message(
    msg_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    result = await db.execute(
        models.Message.__table__.select().where(
            models.Message.id == msg_id,
            models.Message.user_id == current_user.id
        )
    )
    message = result.scalars().first()

    if not message:
        raise HTTPException(status_code=404, detail="Message not found")

    return message

@router.patch("/messages/{msg_id}/read", response_model=schemas.MessageResponse)
async def mark_message_read(
    msg_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    result = await db.execute(
        models.Message.__table__.select().where(
            models.Message.id == msg_id,
            models.Message.user_id == current_user.id
        )
    )
    message = result.scalars().first()

    if not message:
        raise HTTPException(status_code=404, detail="Message not found")

    message.read = True
    await db.commit()
    await db.refresh(message)

    return message
