from services.agent_runner import run_agent


CTO_SCHEMA = """
{
  "role": "CTO",
  "summary": "",
  "analysis": {
    "technical_feasibility": "",
    "system_architecture": "",
    "backend_design": "",
    "frontend_design": "",
    "database_and_deployment": ""
  },
  "recommendation": "",
  "confidence": 0.0
}
"""


def ask_cto(user_message: str) -> dict:
    return run_agent(
        prompt_name="cto",
        role_name="CTO Agent",
        user_message=user_message,
        json_schema=CTO_SCHEMA,
    )