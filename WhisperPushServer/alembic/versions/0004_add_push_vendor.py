"""Add push_vendor to devices table

Revision ID: 0004_add_push_vendor
Revises: 0003_add_password_reset_tokens
Create Date: 2026-05-22 00:00:00

"""
import sqlalchemy as sa
from alembic import op

revision = '0004_add_push_vendor'
down_revision = '0003_add_password_reset_tokens'
branch_labels = None
depends_on = None


def upgrade() -> None:
    conn = op.get_bind()
    inspector = sa.inspect(conn)
    columns = [col['name'] for col in inspector.get_columns('devices')]
    if 'push_vendor' in columns:
        return

    op.add_column('devices', sa.Column('push_vendor', sa.String(length=50), nullable=True))


def downgrade() -> None:
    op.drop_column('devices', 'push_vendor')
