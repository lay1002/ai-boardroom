from services.agent_runner import run_agent


RISK_SCHEMA = """
{
  "role": "Risk",
  "summary": "",
  "analysis": {
    "technical_risk": "",
    "security_risk": "",
    "compliance_risk": "",
    "operational_risk": "",
    "overall_risk_level": ""
  },
  "recommendation": "",
  "confidence": 0.0
}
"""


def ask_risk(user_message: str) -> dict:
    return run_agent(
        prompt_name="risk",
        role_name="Risk Agent",
        user_message=user_message,
        json_schema=RISK_SCHEMA,
    )