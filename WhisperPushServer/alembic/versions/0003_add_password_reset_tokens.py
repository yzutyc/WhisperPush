"""Add password_reset_tokens table

Revision ID: 0003_add_password_reset_tokens
Revises: 0002_add_devices_table
Create Date: 2026-05-18 00:00:00

"""
import sqlalchemy as sa
from alembic import op

revision = '0003_add_password_reset_tokens'
down_revision = '0002_add_devices_table'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # 幂等检查：如果表已存在（例如 Base.metadata.create_all 创建），跳过
    conn = op.get_bind()
    inspector = sa.inspect(conn)
    if 'password_reset_tokens' in inspector.get_table_names():
        return

    op.create_table(
        'password_reset_tokens',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('user_id', sa.Integer(), nullable=True),
        sa.Column('token_hash', sa.String(length=128), nullable=True),
        sa.Column('expires_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('used', sa.Boolean(), nullable=True, server_default=sa.text('0')),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_password_reset_tokens_id'), 'password_reset_tokens', ['id'], unique=False)
    op.create_index(op.f('ix_password_reset_tokens_user_id'), 'password_reset_tokens', ['user_id'], unique=False)
    op.create_index(op.f('ix_password_reset_tokens_token_hash'), 'password_reset_tokens', ['token_hash'], unique=True)


def downgrade() -> None:
    op.drop_index(op.f('ix_password_reset_tokens_token_hash'), table_name='password_reset_tokens')
    op.drop_index(op.f('ix_password_reset_tokens_user_id'), table_name='password_reset_tokens')
    op.drop_index(op.f('ix_password_reset_tokens_id'), table_name='password_reset_tokens')
    op.drop_table('password_reset_tokens')
