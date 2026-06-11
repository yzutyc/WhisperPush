import base64
import hashlib
import io
import secrets

import pyotp
from fastapi import APIRouter, Depends, HTTPException
from qrcode.main import QRCode
from qrcode import constants
from sqlalchemy import select, delete
from sqlalchemy.orm import Session

from app import models, schemas
from app.database import get_db
from app.dependencies import get_current_user
from app.security import verify_password

router = APIRouter()


def get_two_factor(db: Session, user_id: int) -> models.TwoFactor|None:
    """
    获取用户的双因素认证配置
    
    Args:
        db: 数据库会话
        user_id: 用户ID
    
    Returns:
        models.TwoFactor: 双因素认证配置对象，如果不存在则返回 None
    """
    result = db.execute(
        select(models.TwoFactor).where(models.TwoFactor.user_id == user_id)
    )
    return result.scalars().first()


def generate_recovery_codes(db: Session, user_id: int) -> list[str]:
    """
    生成恢复码
    
    生成10个随机恢复码，存储其 SHA256 哈希值，并返回原始码（仅返回一次）。
    
    Args:
        db: 数据库会话
        user_id: 用户ID
    
    Returns:
        list[str]: 10个恢复码的列表
    """
    codes = []
    for _ in range(10):
        code = ''.join([secrets.choice('ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789') for _ in range(4)]) + '-' + \
               ''.join([secrets.choice('ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789') for _ in range(4)])
        code_hash = hashlib.sha256(code.encode()).hexdigest()
        db.add(models.RecoveryCode(user_id=user_id, code_hash=code_hash))
        codes.append(code)
    db.commit()
    return codes


@router.get("/two-factor", response_model=schemas.TwoFactorInfoResponse)
def get_two_factor_info(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """
    获取双因素认证状态接口
    
    检查当前用户是否已启用双因素认证。
    
    Args:
        db: 数据库会话
        current_user: 当前已认证的用户对象
    
    Returns:
        schemas.TwoFactorInfoResponse: 包含启用状态的响应
    """
    two_factor = get_two_factor(db, current_user.id)
    return {"enabled": two_factor.enabled if two_factor else False}


@router.post("/two-factor/enable", response_model=schemas.TwoFactorEnableResponse)
def enable_two_factor(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """
    启用双因素认证接口（第一步）
    
    生成 TOTP 秘钥和 QR 码，供用户扫描配置认证器应用。
    
    Args:
        db: 数据库会话
        current_user: 当前已认证的用户对象
    
    Returns:
        schemas.TwoFactorEnableResponse: 包含秘钥和 QR 码的响应
    
    Raises:
        HTTPException: 400 - 双因素认证已启用
    """
    existing = get_two_factor(db, current_user.id)
    if existing and existing.enabled:
        raise HTTPException(status_code=400, detail="Two-factor authentication is already enabled")

    secret = pyotp.random_base32()
    
    if existing:
        existing.secret = secret
        existing.enabled = False
    else:
        existing = models.TwoFactor(user_id=current_user.id, secret=secret, enabled=False)
        db.add(existing)
    
    db.commit()
    db.refresh(existing)

    issuer = "WhisperPush"
    totp = pyotp.TOTP(secret)
    
    provisioning_uri = totp.provisioning_uri(name=current_user.email, issuer_name=issuer)
    
    qr = QRCode(
        version=1,
        error_correction=constants.ERROR_CORRECT_L,
        box_size=10,
        border=4,
    )
    qr.add_data(provisioning_uri)
    qr.make(fit=True)
    
    img = qr.make_image(fill_color='black', back_color='white')
    buf = io.BytesIO()
    img.save(buf, format='PNG')
    qr_code_base64 = base64.b64encode(buf.getvalue()).decode('utf-8')
    
    return {
        "secret": secret,
        "qr_code_url": f"data:image/png;base64,{qr_code_base64}",
        "otpauth_url": provisioning_uri
    }


@router.post("/two-factor/verify")
def verify_two_factor(
    request: schemas.TwoFactorVerifyRequest,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """
    验证双因素认证接口（第二步）
    
    验证用户输入的 TOTP 验证码，验证成功后启用双因素认证并生成恢复码。
    
    Args:
        request: 包含验证码的请求
        db: 数据库会话
        current_user: 当前已认证的用户对象
    
    Returns:
        dict: 包含状态和恢复码的响应
    
    Raises:
        HTTPException: 400 - 双因素认证未初始化或验证码无效
    """
    two_factor = get_two_factor(db, current_user.id)
    if not two_factor:
        raise HTTPException(status_code=400, detail="Two-factor authentication not initiated")
    
    totp = pyotp.TOTP(two_factor.secret)
    if not totp.verify(request.code):
        raise HTTPException(status_code=400, detail="Invalid verification code")
    
    two_factor.enabled = True
    db.commit()

    codes = generate_recovery_codes(db, current_user.id)
    
    return {"status": "success", "recovery_codes": codes}


@router.post("/two-factor/disable")
def disable_two_factor(
    request: schemas.TwoFactorDisableRequest,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """
    禁用双因素认证接口
    
    验证用户密码后禁用双因素认证，并删除所有恢复码。
    
    Args:
        request: 包含用户密码的请求
        db: 数据库会话
        current_user: 当前已认证的用户对象
    
    Returns:
        dict: 包含状态和消息的响应
    
    Raises:
        HTTPException: 400 - 双因素认证未启用或密码不正确
    """
    two_factor = get_two_factor(db, current_user.id)
    if not two_factor or not two_factor.enabled:
        raise HTTPException(status_code=400, detail="Two-factor authentication is not enabled")
    
    if not verify_password(request.password, current_user.password_hash):
        raise HTTPException(status_code=400, detail="Incorrect password")
    
    two_factor.enabled = False
    db.commit()

    db.execute(delete(models.RecoveryCode).where(models.RecoveryCode.user_id == current_user.id))
    db.commit()
    
    return {"status": "success", "message": "Two-factor authentication disabled"}


@router.get("/two-factor/recovery-codes", response_model=schemas.RecoveryCodesResponse)
def get_recovery_codes(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """
    获取恢复码接口
    
    获取当前用户未使用的恢复码列表。
    
    Args:
        db: 数据库会话
        current_user: 当前已认证的用户对象
    
    Returns:
        schemas.RecoveryCodesResponse: 包含恢复码的响应
    
    Raises:
        HTTPException: 400 - 双因素认证未启用
    """
    two_factor = get_two_factor(db, current_user.id)
    if not two_factor or not two_factor.enabled:
        raise HTTPException(status_code=400, detail="Two-factor authentication is not enabled")
    
    result = db.execute(
        select(models.RecoveryCode).where(
            models.RecoveryCode.user_id == current_user.id,
            models.RecoveryCode.used == False
        )
    )
    codes = result.scalars().all()
    
    return {"recovery_codes": [code.code_hash[:9].upper() for code in codes]}


@router.post("/two-factor/recovery-codes/regenerate", response_model=schemas.RecoveryCodesResponse)
def regenerate_recovery_codes(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """
    重新生成恢复码接口
    
    删除现有恢复码并生成新的恢复码。
    
    Args:
        db: 数据库会话
        current_user: 当前已认证的用户对象
    
    Returns:
        schemas.RecoveryCodesResponse: 包含新恢复码的响应
    
    Raises:
        HTTPException: 400 - 双因素认证未启用
    """
    two_factor = get_two_factor(db, current_user.id)
    if not two_factor or not two_factor.enabled:
        raise HTTPException(status_code=400, detail="Two-factor authentication is not enabled")
    
    db.execute(delete(models.RecoveryCode).where(models.RecoveryCode.user_id == current_user.id))
    db.commit()
    
    codes = generate_recovery_codes(db, current_user.id)
    
    return {"recovery_codes": codes}