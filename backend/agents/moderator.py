import json

from services.llm import ask_llm
from services.prompt_loader import load_prompt
from services.json_parser import parse_json_response


MODERATOR_SCHEMA = """
{
  "board_summary": "",
  "key_consensus": [],
  "key_conflicts": [],
  "risk_flags": [],
  "final_recommendation": "",
  "next_steps": [],
  "confidence": 0.0
}
"""


def run_moderator(question: str, agent_results: dict) -> dict:
    system_prompt = load_prompt("moderator")

    user_message = f"""
You MUST return ONLY valid JSON.

Do not use Markdown.
Do not explain.
Do not output any text before or after the JSON.

Original user question:
{question}

Structured agent outputs:
{json.dumps(agent_results, ensure_ascii=False, indent=2)}

Required JSON schema:
{MODERATOR_SCHEMA}
"""

    raw_response = ask_llm(
        system_prompt=system_prompt,
        user_message=user_message,
        max_tokens=1500,
    )

    result = parse_json_response(raw_response)

    return result