import json

from services.database import get_connection


def save_board_session(response: dict) -> None:
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute(
        """
        INSERT INTO board_sessions (
            request_id,
            question,
            agents_json,
            moderator_json,
            final_report,
            metadata_json,
            created_at
        )
        VALUES (?, ?, ?, ?, ?, ?, ?)
        """,
        (
            response["request_id"],
            response["question"],
            json.dumps(response["agents"], ensure_ascii=False),
            json.dumps(response["moderator"], ensure_ascii=False),
            json.dumps(response["final_report"], ensure_ascii=False),
            json.dumps(response["metadata"], ensure_ascii=False),
            response["timestamp"],
        ),
    )

    conn.commit()
    conn.close()