import asyncio
import logging
import sys

import uvicorn
from sqlalchemy import text
from sqlalchemy.ext.asyncio import create_async_engine

from alembic.config import Config
from alembic.script import ScriptDirectory
from alembic.runtime.environment import EnvironmentContext

from app.config import settings

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    handlers=[logging.StreamHandler()]
)
logger = logging.getLogger(__name__)


async def check_database_connection():
    try:
        engine = create_async_engine(settings.database_url, echo=False)
        async with engine.connect() as conn:
            await conn.execute(text("SELECT 1"))
            await conn.commit()
        await engine.dispose()
        logger.info("数据库连接成功")
        return True
    except Exception as e:
        logger.error(f"数据库连接失败: {str(e)}")
        return False


async def run_migrations():
    try:
        alembic_cfg = Config("alembic.ini")
        alembic_cfg.set_main_option("sqlalchemy.url", settings.database_url)
        
        script = ScriptDirectory.from_config(alembic_cfg)
        
        def upgrade(rev, context):
            return script._upgrade_revs("heads", rev)
        
        def run_migrations_with_connection(connection):
            env = EnvironmentContext(alembic_cfg, script, fn=upgrade)
            env.configure(connection=connection)
            env.run_migrations()
        
        connectable = create_async_engine(settings.database_url)
        
        async with connectable.connect() as connection:
            await connection.run_sync(run_migrations_with_connection)
            await connection.commit()
        
        await connectable.dispose()
        
        logger.info("数据库迁移完成")
        return True
    except Exception as e:
        logger.error(f"数据库迁移失败: {str(e)}")
        return False


async def main():
    logger.info("正在检查数据库连接...")
    if not await check_database_connection():
        logger.error("数据库连接失败，无法启动服务")
        sys.exit(1)
    
    logger.info("正在执行数据库迁移...")
    if not await run_migrations():
        logger.error("数据库迁移失败，无法启动服务")
        sys.exit(1)
    
    logger.info("启动服务...")
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)


if __name__ == "__main__":
    asyncio.run(main())