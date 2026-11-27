"""Add user_type and onboarding_completed to users table

Revision ID: c1a2b3c4d5e6
Revises: b090d8e9ab12
Create Date: 2026-08-27 22:12:00.000000

"""
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = 'c1a2b3c4d5e6'
down_revision = 'b090d8e9ab12'
branch_labels = None
depends_on = None

def upgrade():
    op.add_column('users', sa.Column('user_type', sa.String(), server_default='reader', nullable=False))
    op.add_column('users', sa.Column('onboarding_completed', sa.Boolean(), server_default='false', nullable=False))

def downgrade():
    op.drop_column('users', 'onboarding_completed')
    op.drop_column('users', 'user_type')
