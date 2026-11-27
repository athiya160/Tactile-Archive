"""merge_heads

Revision ID: fe835ec7bea9
Revises: 9a433bed2cad, e7f8g9h0i1j2
Create Date: 2026-08-28 02:31:13.458501

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'fe835ec7bea9'
down_revision: Union[str, Sequence[str], None] = ('9a433bed2cad', 'e7f8g9h0i1j2')
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    pass


def downgrade() -> None:
    """Downgrade schema."""
    pass
