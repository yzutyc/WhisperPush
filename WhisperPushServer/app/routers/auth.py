from datetime import timedelta

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app import dependencies
from app import models, schemas
from app.config import settings
from app.database import get_db
from app.security import verify_password, get_password_hash, create_access_token, get_user_by_email, \
    get_user_by_username

router = APIRouter()

@router.post("/register", response_model=schemas.UserResponse)
async def register(user: schemas.UserCreate, db: AsyncSession = Depends(get_db)):
    db_user = await get_user_by_email(db, email=user.email)
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    db_user = await get_user_by_username(db, username=user.username)
    if db_user:
        raise HTTPException(status_code=400, detail="Username already taken")
    
    password_hash = get_password_hash(user.password)
    new_user = models.User(
        username=user.username,
        email=user.email,
        password_hash=password_hash
    )
    db.add(new_user)
    await db.commit()
    await db.refresh(new_user)
    return new_user

@router.post("/login", response_model=schemas.Token)
async def login(form_data: schemas.LoginRequest, db: AsyncSession = Depends(get_db)):
    user = await get_user_by_email(db, email=form_data.username_or_email)
    if not user:
        user = await get_user_by_username(db, username=form_data.username_or_email)
    
    if not user or not verify_password(form_data.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username/email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    access_token_expires = timedelta(minutes=settings.access_token_expire_minutes)
    access_token = create_access_token(
        data={"sub": user.id}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}

@router.get("/me", response_model=schemas.UserResponse)
async def read_users_me(current_user: models.User = Depends(dependencies.get_current_user)):
    return current_user