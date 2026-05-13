"""Add devices table

Revision ID: 0002_add_devices_table
Revises: 0001_initial_migration
Create Date: 2026-05-13 00:01:00

"""
import sqlalchemy as sa
from alembic import op

revision = '0002_add_devices_table'
down_revision = '0001_initial_migration'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        'devices',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('user_id', sa.Integer(), nullable=True),
        sa.Column('device_type', sa.String(length=20), nullable=True),
        sa.Column('device_token', sa.String(length=255), nullable=True),
        sa.Column('device_name', sa.String(length=100), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.Column('is_active', sa.Boolean(), nullable=True),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_devices_id'), 'devices', ['id'], unique=False)
    op.create_index(op.f('ix_devices_user_id'), 'devices', ['user_id'], unique=False)


def downgrade() -> None:
    op.drop_index(op.f('ix_devices_user_id'), table_name='devices')
    op.drop_index(op.f('ix_devices_id'), table_name='devices')
    op.drop_table('devices')
