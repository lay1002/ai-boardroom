from services.agent_runner import run_agent


CFO_SCHEMA = """
{
  "role": "CFO",
  "summary": "",
  "analysis": {
    "development_cost": "",
    "maintenance_cost": "",
    "api_cost": "",
    "human_resource_cost": "",
    "roi_analysis": "",
    "cost_risk": ""
  },
  "recommendation": "",
  "confidence": 0.0
}
"""


def ask_cfo(user_message: str) -> dict:
    return run_agent(
        prompt_name="cfo",
        role_name="CFO Agent",
        user_message=user_message,
        json_schema=CFO_SCHEMA,
    )