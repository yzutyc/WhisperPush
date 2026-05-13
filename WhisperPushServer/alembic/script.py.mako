"""${message}

Revision ID: ${rev_id}
Revises: ${revises if revises else "None"}
Create Date: ${create_date}

"""
from alembic import op
import sqlalchemy as sa
${imports if imports else ""}

# revision identifiers, used by Alembic.
revision = "${rev_id}"
down_revision = ${revises if revises else "None"}
branch_labels = ${branch_labels}
depends_on = None


def upgrade() -> None:
    ${upgrades if upgrades else "pass"}


def downgrade() -> None:
    ${downgrades if downgrades else "pass"}