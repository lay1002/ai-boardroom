"""Prompt Generator.

Turns a single Product Owner requirement description into a fixed
four-section Markdown document containing ready-to-paste prompts for
ChatGPT, Claude Code, and Codex, plus a Next Step recommendation. See
`reviews/sprint-008/round-001/architecture.md` sections 6-8.
"""

from __future__ import annotations

from backend.app.engines.prompt_generator.errors import BlankRequirementError


def _chatgpt_architecture_prompt(requirement: str) -> str:
    return (
        "你是本專案的 Chief Product Architect。\n\n"
        "以下是 Product Owner 的需求描述：\n\n"
        f'"""\n{requirement}\n"""\n\n'
        "請完成以下工作：\n\n"
        "1. 先確認需求範圍，若有不明確之處請明確提出問題，不可自行假設。\n"
        "2. 產生最小可行 Architecture（MVP）。\n"
        "3. 明確列出 In Scope 與 Out of Scope。\n"
        "4. 遵守 MVP First，Architecture Second，Platform Last，不擴大架構範圍。\n"
        "5. 一次只做一件最重要的事情。\n\n"
        "請輸出結構化的 Architecture 文件。"
    )


def _claude_code_implementation_prompt(requirement: str) -> str:
    return (
        "你是本專案的 Implementation AI（Claude Code）。\n\n"
        "以下是本次要實作的需求描述：\n\n"
        f'"""\n{requirement}\n"""\n\n'
        "請完成以下工作：\n\n"
        "1. 先閱讀必要文件（AGENTS.md、已核准的 architecture.md 等）。\n"
        "2. 依照已核准的 Architecture 實作，不擴大範圍。\n"
        "3. 不修改 Review Bridge。\n"
        "4. 不要 commit。\n"
        "5. 完成後更新 claude_report.md。\n"
        "6. 回報測試方式與測試結果。"
    )


def _codex_review_prompt(requirement: str) -> str:
    return (
        "你是本專案的 Reviewer AI（Codex）。\n\n"
        "以下是本次要 Review 的需求描述：\n\n"
        f'"""\n{requirement}\n"""\n\n'
        "請完成以下工作：\n\n"
        "1. 只做 Review，不可修改程式碼。\n"
        "2. 檢查實作是否符合已核准的 Architecture。\n"
        "3. 檢查是否有擴大範圍。\n"
        "4. 檢查是否修改了禁止項目（例如 Review Bridge）。\n"
        "5. 檢查測試是否足夠。\n"
        "6. 輸出 codex_review.md。\n"
        "7. 不要 commit。"
    )


def _next_step() -> str:
    return (
        "1. 請先將「1. ChatGPT Architecture Prompt」提供給 ChatGPT，取得核准的 Architecture。\n"
        "2. Architecture 核准後，再將「2. Claude Code Implementation Prompt」提供給 "
        "Claude Code 進行實作。\n"
        "3. 實作完成後，再將「3. Codex Review Prompt」提供給 Codex 進行 Review。\n\n"
        "請一次只交付一個步驟給對應的 AI，不要同時執行多個角色的工作。"
    )


def generate_prompt_markdown(requirement: str) -> str:
    """Build the fixed four-section Markdown prompt bundle for one requirement.

    Raises:
        BlankRequirementError: `requirement` is empty or whitespace-only.
    """
    cleaned = requirement.strip()
    if not cleaned:
        raise BlankRequirementError("requirement must not be blank")

    return (
        "# AI 協作 Prompt\n\n"
        "## 1. ChatGPT Architecture Prompt\n\n"
        f"{_chatgpt_architecture_prompt(cleaned)}\n\n"
        "## 2. Claude Code Implementation Prompt\n\n"
        f"{_claude_code_implementation_prompt(cleaned)}\n\n"
        "## 3. Codex Review Prompt\n\n"
        f"{_codex_review_prompt(cleaned)}\n\n"
        "## 4. Next Step\n\n"
        f"{_next_step()}\n"
    )
