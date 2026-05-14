from app.database import engine
from sqlalchemy import text

print('Migrating two_factor.secret column...')
with engine.begin() as conn:
    conn.execute(text("ALTER TABLE two_factor ALTER COLUMN secret TYPE VARCHAR(32)"))
print('Migration completed successfully!')
