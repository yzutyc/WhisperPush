import hashlib
import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app import models, schemas
from app.database import get_db
from app.dependencies import get_current_user

router = APIRouter()

@router.post("/", response_model=schemas.SecretWithKeyResponse)
async def create_secret(
    secret_data: schemas.SecretCreate,
    db: AsyncSession = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    secret_key = str(uuid.uuid4())
    secret_key_hash = hashlib.sha256(secret_key.encode()).hexdigest()
    
    new_secret = models.Secret(
        user_id=current_user.id,
        secret_key_hash=secret_key_hash,
        name=secret_data.name
    )
    db.add(new_secret)
    await db.commit()
    await db.refresh(new_secret)
    
    return schemas.SecretWithKeyResponse(
        id=new_secret.id,
        user_id=new_secret.user_id,
        name=new_secret.name,
        created_at=new_secret.created_at,
        is_active=new_secret.is_active,
        secret_key=secret_key
    )

@router.get("/", response_model=list[schemas.SecretResponse])
async def list_secrets(
    db: AsyncSession = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    result = await db.execute(
        models.Secret.__table__.select().where(models.Secret.user_id == current_user.id)
    )
    return result.scalars().all()

@router.delete("/{secret_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_secret(
    secret_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    result = await db.execute(
        models.Secret.__table__.select().where(
            models.Secret.id == secret_id,
            models.Secret.user_id == current_user.id
        )
    )
    secret = result.scalars().first()
    
    if not secret:
        raise HTTPException(status_code=404, detail="Secret not found")
    
    await db.delete(secret)
    await db.commit()
    return None