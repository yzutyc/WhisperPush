import hashlib
import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app import models, schemas
from app.database import get_db
from app.dependencies import get_current_user

router = APIRouter()


@router.post("/", response_model=schemas.SecretWithKeyResponse)
def create_secret(
    secret_data: schemas.SecretCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """
    创建 API 秘钥接口
    
    生成新的 UUID 秘钥，存储其 SHA256 哈希值，并返回原始秘钥（仅返回一次）。
    
    Args:
        secret_data: 秘钥创建数据，包含 name
        db: 数据库会话
        current_user: 当前已认证的用户对象
    
    Returns:
        schemas.SecretWithKeyResponse: 包含原始秘钥的响应（仅返回一次）
    """
    secret_key = str(uuid.uuid4())
    secret_key_hash = hashlib.sha256(secret_key.encode()).hexdigest()
    
    new_secret = models.Secret(
        user_id=current_user.id,
        secret_key_hash=secret_key_hash,
        name=secret_data.name
    )
    db.add(new_secret)
    db.commit()
    db.refresh(new_secret)
    
    return schemas.SecretWithKeyResponse(
        id=new_secret.id,
        user_id=new_secret.user_id,
        name=new_secret.name,
        created_at=new_secret.created_at,
        is_active=new_secret.is_active,
        secret_key=secret_key
    )


@router.get("/", response_model=list[schemas.SecretResponse])
def list_secrets(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """
    获取秘钥列表接口
    
    获取当前用户的所有 API 秘钥（不包含原始秘钥）。
    
    Args:
        db: 数据库会话
        current_user: 当前已认证的用户对象
    
    Returns:
        list[schemas.SecretResponse]: 秘钥列表
    """
    result = db.execute(
        select(models.Secret).where(models.Secret.user_id == current_user.id)
    )
    return result.scalars().all()


@router.delete("/{secret_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_secret(
    secret_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """
    删除秘钥接口
    
    删除指定的 API 秘钥。
    
    Args:
        secret_id: 秘钥ID
        db: 数据库会话
        current_user: 当前已认证的用户对象
    
    Returns:
        None: 204 状态码，无返回内容
    
    Raises:
        HTTPException: 404 - 秘钥不存在或无权访问
    """
    result = db.execute(
        select(models.Secret).where(
            models.Secret.id == secret_id,
            models.Secret.user_id == current_user.id
        )
    )
    secret = result.scalars().first()
    
    if not secret:
        raise HTTPException(status_code=404, detail="Secret not found")
    
    db.delete(secret)
    db.commit()
    return None