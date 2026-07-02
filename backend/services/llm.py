from anthropic import Anthropic
from config import AGNES_API_KEY, AGNES_BASE_URL, AGNES_MODEL


client = Anthropic(
    api_key=AGNES_API_KEY,
    base_url=AGNES_BASE_URL,
)


def ask_llm(system_prompt: str, user_message: str, max_tokens: int = 1200) -> str:
    response = client.messages.create(
        model=AGNES_MODEL,
        max_tokens=max_tokens,
        system=system_prompt,
        messages=[
            {
                "role": "user",
                "content": user_message,
            }
        ],
    )

    print("========== LLM DEBUG ==========")
    print("MODEL:", response.model)
    print("CONTENT:", response.content)
    print("RAW RESPONSE:", response)
    print("===============================")

    return response.content[0].text