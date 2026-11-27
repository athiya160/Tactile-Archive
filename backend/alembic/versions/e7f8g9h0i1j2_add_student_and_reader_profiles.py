"""Add student_profiles and reader_profiles tables

Revision ID: e7f8g9h0i1j2
Revises: c1a2b3c4d5e6
Create Date: 2026-08-27 23:03:00.000000

"""
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = 'e7f8g9h0i1j2'
down_revision = 'c1a2b3c4d5e6'
branch_labels = None
depends_on = None

def upgrade():
    op.create_table(
        'student_profiles',
        sa.Column('id', sa.Integer(), primary_key=True, index=True),
        sa.Column('user_id', sa.Integer(), sa.ForeignKey('users.id', ondelete='CASCADE'), unique=True, index=True),
        sa.Column('education_level', sa.String(), nullable=True),
        sa.Column('course', sa.String(), nullable=True),
        sa.Column('subjects', sa.Text(), nullable=True),
        sa.Column('exam_goal', sa.String(), nullable=True),
        sa.Column('study_duration', sa.Integer(), server_default='60'),
        sa.Column('difficulty_level', sa.String(), server_default='Intermediate'),
        sa.Column('academic_interests', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(), server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.Column('updated_at', sa.DateTime(), server_default=sa.text('CURRENT_TIMESTAMP')),
    )

    op.create_table(
        'reader_profiles',
        sa.Column('id', sa.Integer(), primary_key=True, index=True),
        sa.Column('user_id', sa.Integer(), sa.ForeignKey('users.id', ondelete='CASCADE'), unique=True, index=True),
        sa.Column('genres', sa.Text(), nullable=True),
        sa.Column('favorite_authors', sa.Text(), nullable=True),
        sa.Column('reading_goal', sa.String(), nullable=True),
        sa.Column('preferred_duration', sa.Integer(), server_default='30'),
        sa.Column('favorite_moods', sa.Text(), nullable=True),
        sa.Column('reading_frequency', sa.String(), server_default='Daily'),
        sa.Column('created_at', sa.DateTime(), server_default=sa.text('CURRENT_TIMESTAMP')),
        sa.Column('updated_at', sa.DateTime(), server_default=sa.text('CURRENT_TIMESTAMP')),
    )

def downgrade():
    op.drop_table('reader_profiles')
    op.drop_table('student_profiles')
