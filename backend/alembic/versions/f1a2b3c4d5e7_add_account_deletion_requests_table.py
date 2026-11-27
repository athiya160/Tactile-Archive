"""Add account_deletion_requests table

Revision ID: f1a2b3c4d5e7
Revises: fe835ec7bea9
Create Date: 2026-11-20 01:25:00.000000

"""
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = 'f1a2b3c4d5e7'
down_revision = 'fe835ec7bea9'
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        'account_deletion_requests',
        sa.Column('id', sa.Integer(), primary_key=True, autoincrement=True, nullable=False),
        sa.Column('request_id', sa.String(length=32), nullable=False),
        sa.Column('user_id', sa.Integer(), sa.ForeignKey('users.id', ondelete='SET NULL'), nullable=True),
        sa.Column('email', sa.String(length=255), nullable=False),
        sa.Column('reason', sa.String(length=500), nullable=True),
        sa.Column('status', sa.String(length=50), server_default='pending', nullable=False),
        sa.Column('ip_hash', sa.String(length=64), nullable=True),
        sa.Column('resolution_notes', sa.String(length=1000), nullable=True),
        sa.Column('processed_by', sa.Integer(), sa.ForeignKey('users.id', ondelete='SET NULL'), nullable=True),
        sa.Column('processed_at', sa.DateTime(), nullable=True),
        sa.Column('created_at', sa.DateTime(), server_default=sa.func.now(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), server_default=sa.func.now(), nullable=False),
    )
    op.create_index('uq_idx_adr_request_id', 'account_deletion_requests', ['request_id'], unique=True)
    op.create_index('idx_adr_email', 'account_deletion_requests', ['email'], unique=False)
    op.create_index('idx_adr_status', 'account_deletion_requests', ['status'], unique=False)
    op.create_index('idx_adr_user_id', 'account_deletion_requests', ['user_id'], unique=False)
    op.create_index('idx_adr_created_at', 'account_deletion_requests', ['created_at'], unique=False)


def downgrade():
    op.drop_index('idx_adr_created_at', table_name='account_deletion_requests')
    op.drop_index('idx_adr_user_id', table_name='account_deletion_requests')
    op.drop_index('idx_adr_status', table_name='account_deletion_requests')
    op.drop_index('idx_adr_email', table_name='account_deletion_requests')
    op.drop_index('uq_idx_adr_request_id', table_name='account_deletion_requests')
    op.drop_table('account_deletion_requests')
