import logging
import sys

import uvicorn
from sqlalchemy import create_engine, text

from app.config import settings

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    handlers=[logging.StreamHandler()]
)
logger = logging.getLogger(__name__)


def check_database_connection():
    try:
        engine = create_engine(settings.database_url)
        with engine.begin() as conn:
            conn.execute(text("SELECT 1"))
        logger.info("数据库连接成功")
        return True
    except Exception as e:
        logger.error(f"数据库连接失败: {str(e)}")
        return False


def create_tables():
    try:
        from app.database import engine, Base
        import app.models  # noqa: F401 — 确保所有模型表注册到 Base.metadata
        Base.metadata.create_all(bind=engine)
        logger.info("数据库表创建成功")
        return True
    except Exception as e:
        logger.error(f"数据库表创建失败: {str(e)}")
        return False


def main():
    logger.info("正在检查数据库连接...")
    if not check_database_connection():
        logger.error("数据库连接失败，无法启动服务")
        sys.exit(1)
    
    logger.info("正在创建数据库表...")
    if not create_tables():
        logger.error("数据库表创建失败，无法启动服务")
        sys.exit(1)
    
    logger.info("启动服务...")
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)


if __name__ == "__main__":
    main()