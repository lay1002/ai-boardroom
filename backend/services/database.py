import psycopg2
from psycopg2.extras import RealDictCursor


DATABASE_CONFIG = {
    "dbname": "boardroom",
    "user": "boardroom",
    "password": "boardroom_password",
    "host": "localhost",
    "port": "5432",
}


def get_connection():
    return psycopg2.connect(
        **DATABASE_CONFIG,
        cursor_factory=RealDictCursor,
    )


def init_db():
    """
    PostgreSQL schema is managed by backend/sql/schema.sql.
    Keep this function for compatibility with existing startup code.
    """
    return None