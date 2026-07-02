from services.agent_runner import run_agent


CEO_SCHEMA = """
{
  "role": "CEO",
  "summary": "",
  "analysis": {
    "business_value": "",
    "target_users": "",
    "market_demand": "",
    "product_positioning": ""
  },
  "recommendation": "",
  "confidence": 0.0
}
"""


def ask_ceo(user_message: str) -> dict:
    return run_agent(
        prompt_name="ceo",
        role_name="CEO Agent",
        user_message=user_message,
        json_schema=CEO_SCHEMA,
    )