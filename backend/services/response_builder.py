from datetime import datetime, timezone
from uuid import uuid4

from config import AGNES_MODEL
from services.report_builder import build_final_report


def build_boardroom_response(
    question: str,
    agents: dict,
    moderator: dict,
    execution_time_ms: int | None = None,
) -> dict:
    final_report = build_final_report(
        question=question,
        moderator=moderator,
    )

    return {
        "success": True,
        "request_id": f"br_{datetime.now().strftime('%Y%m%d')}_{uuid4().hex[:8]}",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "question": question,
        "agents": agents,
        "moderator": moderator,
        "final_report": {
            "title": "AI Boardroom Final Report",
            "format": "markdown",
            "content": final_report,
        },
        "metadata": {
            "version": "1.7.1",
            "model": AGNES_MODEL,
            "parallel_execution": True,
            "total_agents": len(agents),
            "agent_roles": list(agents.keys()),
            "execution_time_ms": execution_time_ms,
        },
    }