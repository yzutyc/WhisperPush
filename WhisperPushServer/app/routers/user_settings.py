from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import get_current_user
from app.models import User

router = APIRouter(prefix="/api/users/me/settings", tags=["user_settings"])


class UserSettings(BaseModel):
    notifications_enabled: bool

    class Config:
        orm_mode = True


class UpdateSettingsRequest(BaseModel):
    notifications_enabled: bool


@router.get("", response_model=UserSettings, summary="获取当前用户设置")
async def get_user_settings(
    current_user: User = Depends(get_current_user)
):
    """
    获取当前登录用户的设置信息。
    
    Returns:
        UserSettings: 用户设置对象，包含推送通知开关状态
    """
    return UserSettings(
        notifications_enabled=current_user.notifications_enabled
    )


@router.put("", response_model=UserSettings, summary="更新用户设置")
async def update_user_settings(
    settings: UpdateSettingsRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    更新当前登录用户的设置信息。
    
    Args:
        settings: 用户设置对象，包含推送通知开关状态
        
    Returns:
        UserSettings: 更新后的用户设置对象
        :param settings:
        :param db:
        :param current_user:
    """
    current_user.notifications_enabled = settings.notifications_enabled
    db.commit()
    db.refresh(current_user)
    
    return UserSettings(
        notifications_enabled=current_user.notifications_enabled
    )