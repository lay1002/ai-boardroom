import time
from concurrent.futures import ThreadPoolExecutor

from agents.ceo import ask_ceo
from agents.cto import ask_cto
from agents.cfo import ask_cfo
from agents.risk import ask_risk
from agents.execution import ask_execution
from agents.moderator import run_moderator
from services.response_builder import build_boardroom_response
from repositories.board_repository import BoardRepository


def run_boardroom(question: str) -> dict:
    start_time = time.time()

    with ThreadPoolExecutor(max_workers=5) as executor:
        futures = {
            "ceo": executor.submit(ask_ceo, question),
            "cto": executor.submit(ask_cto, question),
            "cfo": executor.submit(ask_cfo, question),
            "risk": executor.submit(ask_risk, question),
            "execution": executor.submit(ask_execution, question),
        }

        agent_results = {
            role: future.result()
            for role, future in futures.items()
        }

    moderator_result = run_moderator(
        question=question,
        agent_results=agent_results,
    )

    execution_time_ms = int((time.time() - start_time) * 1000)

    response = build_boardroom_response(
        question=question,
        agents=agent_results,
        moderator=moderator_result,
        execution_time_ms=execution_time_ms,
    )

    try:
        repo = BoardRepository()
        session_id = repo.save(response)

        response["metadata"]["history_saved"] = True
        response["metadata"]["session_id"] = session_id

    except Exception as e:
        response["metadata"]["history_saved"] = False
        response["metadata"]["history_error"] = str(e)

    return response