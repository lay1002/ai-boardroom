from services.agent_runner import run_agent


EXECUTION_SCHEMA = """
{
  "role": "Execution",
  "summary": "",
  "analysis": {
    "implementation_plan": "",
    "milestones": "",
    "timeline": "",
    "resource_requirements": "",
    "success_criteria": ""
  },
  "recommendation": "",
  "confidence": 0.0
}
"""


def ask_execution(user_message: str) -> dict:
    return run_agent(
        prompt_name="execution",
        role_name="Execution Agent",
        user_message=user_message,
        json_schema=EXECUTION_SCHEMA,
    )