from services.llm import ask_llm
from services.prompt_loader import load_prompt
from services.json_parser import parse_json_response


def run_agent(
    prompt_name: str,
    role_name: str,
    user_message: str,
    json_schema: str,
    max_tokens: int = 800,
) -> dict:
    strict_user_message = f"""
請根據以下問題，從 {role_name} 角度回答。

使用者問題：
{user_message}

重要規則：
你只能輸出合法 JSON。
不要輸出 Markdown。
不要輸出 ```json。
不要輸出任何 JSON 以外的文字。

JSON 格式如下：
{json_schema}
"""

    response = ask_llm(
        system_prompt=load_prompt(prompt_name),
        user_message=strict_user_message,
        max_tokens=max_tokens,
    )

    return parse_json_response(response)
