from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

from app.config import settings

Base = declarative_base()

engine = create_engine(settings.database_url)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

from app import models

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()