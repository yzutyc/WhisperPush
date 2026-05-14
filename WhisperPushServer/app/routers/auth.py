from datetime import timedelta

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app import dependencies
from app import models, schemas
from app.config import settings
from app.database import get_db
from app.security import verify_password, get_password_hash, create_access_token, get_user_by_email, \
    get_user_by_username

router = APIRouter()


@router.post("/register", response_model=schemas.UserResponse)
def register(user: schemas.UserCreate, db: Session = Depends(get_db)):
    """
    用户注册接口
    
    创建新用户账户，验证邮箱和用户名唯一性，存储密码哈希值。
    
    Args:
        user: 用户注册数据，包含 username、email、password
        db: 数据库会话
    
    Returns:
        schemas.UserResponse: 注册成功的用户信息
    
    Raises:
        HTTPException: 400 - 邮箱已注册或用户名已被占用
    """
    db_user = get_user_by_email(db, email=user.email)
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    db_user = get_user_by_username(db, username=user.username)
    if db_user:
        raise HTTPException(status_code=400, detail="Username already taken")
    
    password_hash = get_password_hash(user.password)
    new_user = models.User(
        username=user.username,
        email=user.email,
        password_hash=password_hash
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user


@router.post("/login", response_model=schemas.Token)
def login(form_data: schemas.LoginRequest, db: Session = Depends(get_db)):
    """
    用户登录接口
    
    通过邮箱或用户名验证用户身份，生成 JWT 访问令牌。
    
    Args:
        form_data: 登录请求数据，包含 username_or_email 和 password
        db: 数据库会话
    
    Returns:
        schemas.Token: 包含 access_token 和 token_type 的令牌响应
    
    Raises:
        HTTPException: 401 - 用户名/邮箱或密码不正确
    """
    user = get_user_by_email(db, email=form_data.username_or_email)
    if not user:
        user = get_user_by_username(db, username=form_data.username_or_email)
    
    if not user or not verify_password(form_data.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username/email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    access_token_expires = timedelta(minutes=settings.access_token_expire_minutes)
    access_token = create_access_token(
        data={"sub": str(user.id)}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer", "username": user.username}


@router.get("/me", response_model=schemas.UserResponse)
def read_users_me(current_user: models.User = Depends(dependencies.get_current_user)):
    """
    获取当前用户信息
    
    返回当前已认证用户的详细信息。
    
    Args:
        current_user: 当前已认证的用户对象（通过 JWT 令牌解析）
    
    Returns:
        schemas.UserResponse: 当前用户信息
    """
    return current_user


@router.post("/logout")
def logout(current_user: models.User = Depends(dependencies.get_current_user)):
    """
    用户登出接口
    
    执行用户登出操作。当前实现为无状态登出，客户端应自行销毁令牌。
    
    Args:
        current_user: 当前已认证的用户对象
    
    Returns:
        dict: 包含状态和消息的响应
    """
    return {"status": "success", "message": "Logged out successfully"}


@router.post("/forgot-password")
def forgot_password(
    request: schemas.ForgotPasswordRequest,
    db: Session = Depends(get_db)
):
    """
    忘记密码接口
    
    验证用户邮箱并发送密码重置链接（预留接口）。
    
    Args:
        request: 包含用户邮箱的请求
        db: 数据库会话
    
    Returns:
        dict: 包含状态和消息的响应
    
    Raises:
        HTTPException: 404 - 用户不存在
    """
    user = get_user_by_email(db, email=request.email)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    return {"status": "success", "message": "Password reset link sent to your email"}


@router.post("/change-password")
def change_password(
    request: schemas.ChangePasswordRequest,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(dependencies.get_current_user)
):
    """
    修改密码接口
    
    验证当前密码后更新用户密码。
    
    Args:
        request: 修改密码请求，包含 current_password 和 new_password
        db: 数据库会话
        current_user: 当前已认证的用户对象
    
    Returns:
        dict: 包含状态和消息的响应
    
    Raises:
        HTTPException: 400 - 当前密码不正确
    """
    if not verify_password(request.current_password, current_user.password_hash):
        raise HTTPException(status_code=400, detail="Current password is incorrect")
    
    new_password_hash = get_password_hash(request.new_password)
    current_user.password_hash = new_password_hash
    db.commit()
    
    return {"status": "success", "message": "Password changed successfully"}