import json
from services.database import get_connection


class BoardRepository:
    def create_session(self, response: dict) -> int:
        metadata = response.get("metadata", {})

        conn = get_connection()
        cursor = conn.cursor()

        cursor.execute(
            """
            INSERT INTO board_sessions (
                request_id,
                question,
                model,
                version,
                execution_time_ms
            )
            VALUES (%s, %s, %s, %s, %s)
            RETURNING id
            """,
            (
                response.get("request_id"),
                response.get("question"),
                metadata.get("model"),
                metadata.get("version"),
                metadata.get("execution_time_ms"),
            ),
        )

        session_id = cursor.fetchone()["id"]

        conn.commit()
        cursor.close()
        conn.close()

        return session_id

    def save_agents(self, session_id: int, agents: dict) -> None:
        conn = get_connection()
        cursor = conn.cursor()

        for role, agent in agents.items():
            cursor.execute(
                """
                INSERT INTO board_agents (
                    session_id,
                    role,
                    summary,
                    analysis,
                    recommendation,
                    confidence
                )
                VALUES (%s, %s, %s, %s::jsonb, %s, %s)
                """,
                (
                    session_id,
                    agent.get("role", role),
                    agent.get("summary"),
                    json.dumps(agent.get("analysis", {}), ensure_ascii=False),
                    agent.get("recommendation"),
                    agent.get("confidence"),
                ),
            )

        conn.commit()
        cursor.close()
        conn.close()

    def save_report(self, session_id: int, final_report: dict, moderator: dict) -> None:
        conn = get_connection()
        cursor = conn.cursor()

        cursor.execute(
            """
            INSERT INTO board_reports (
                session_id,
                title,
                report_markdown,
                summary,
                recommendation,
                confidence
            )
            VALUES (%s, %s, %s, %s, %s, %s)
            """,
            (
                session_id,
                final_report.get("title"),
                final_report.get("content"),
                moderator.get("board_summary"),
                moderator.get("final_recommendation"),
                moderator.get("confidence"),
            ),
        )

        conn.commit()
        cursor.close()
        conn.close()

    def save(self, response: dict) -> int:
        session_id = self.create_session(response)
        self.save_agents(session_id, response.get("agents", {}))
        self.save_report(
            session_id=session_id,
            final_report=response.get("final_report", {}),
            moderator=response.get("moderator", {}),
        )
        return session_id
