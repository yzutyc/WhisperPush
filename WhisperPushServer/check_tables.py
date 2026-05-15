from sqlalchemy import text

from app.database import engine

print('Checking tables...')
with engine.begin() as conn:
    result = conn.execute(text("SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'"))
    tables = [row[0] for row in result]
    print(f"Tables in database: {tables}")
    
    if 'two_factor' in tables:
        print("two_factor table exists!")
    else:
        print("ERROR: two_factor table does NOT exist!")
