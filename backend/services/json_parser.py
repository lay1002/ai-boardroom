"""
json_parser.py

AI Boardroom V1.2
-----------------
將 LLM 回覆解析成 Python dict。

支援：
- 純 JSON
- ```json ... ```
- ``` ... ```
- 前後多餘文字
- 空白/BOM
"""

import json
import re
from typing import Any, Dict


class JSONParseError(Exception):
    """LLM JSON Parse Error"""


def _extract_json(text: str) -> str:
    """
    從 LLM 回覆中取出 JSON。
    """

    if not text:
        raise JSONParseError("Empty response")

    # 去除 BOM
    text = text.replace("\ufeff", "").strip()

    # ```json ... ```
    match = re.search(r"```(?:json)?\s*(.*?)```", text, re.DOTALL)
    if match:
        return match.group(1).strip()

    # 找第一個 {
    start = text.find("{")
    end = text.rfind("}")

    if start != -1 and end != -1:
        return text[start : end + 1]

    raise JSONParseError("Cannot find JSON object")


def parse_json_response(text: str) -> Dict[str, Any]:
    """
    將 LLM 回覆轉成 dict。

    Raises:
        JSONParseError
    """

    json_text = _extract_json(text)

    try:
        return json.loads(json_text)

    except json.JSONDecodeError as e:
        raise JSONParseError(
            f"Invalid JSON\n"
            f"{e}\n\n"
            f"========== RAW ==========\n"
            f"{text}\n"
            f"========================="
        )