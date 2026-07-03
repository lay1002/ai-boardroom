import subprocess
import sys
from pathlib import Path

import pytest

from backend.app.engines.prompt_generator.errors import BlankRequirementError
from backend.app.engines.prompt_generator.generator import generate_prompt_markdown

PROJECT_ROOT = Path(__file__).resolve().parents[3]
CLI_PATH = PROJECT_ROOT / "scripts" / "generate_prompt.py"


def test_generate_prompt_markdown_contains_four_sections_in_order():
    markdown = generate_prompt_markdown("我要新增登入功能")
    assert markdown.index("## 1. ChatGPT Architecture Prompt") < markdown.index(
        "## 2. Claude Code Implementation Prompt"
    )
    assert markdown.index("## 2. Claude Code Implementation Prompt") < markdown.index(
        "## 3. Codex Review Prompt"
    )
    assert markdown.index("## 3. Codex Review Prompt") < markdown.index(
        "## 4. Next Step"
    )


def test_generate_prompt_markdown_starts_with_title():
    markdown = generate_prompt_markdown("我要新增登入功能")
    assert markdown.startswith("# AI 協作 Prompt")


def test_generate_prompt_markdown_embeds_requirement_in_first_three_blocks():
    markdown = generate_prompt_markdown("我要新增登入功能")
    assert markdown.count("我要新增登入功能") == 3


def test_generate_prompt_markdown_strips_surrounding_whitespace():
    markdown = generate_prompt_markdown("  我要新增登入功能  \n")
    assert "  我要新增登入功能  " not in markdown
    assert markdown.count("我要新增登入功能") == 3


def test_chatgpt_block_requires_scope_and_mvp_rules():
    markdown = generate_prompt_markdown("需求描述")
    assert "In Scope" in markdown
    assert "Out of Scope" in markdown
    assert "MVP First" in markdown
    assert "不擴大架構" in markdown


def test_claude_block_requires_no_review_bridge_and_no_commit():
    markdown = generate_prompt_markdown("需求描述")
    assert "不修改 Review Bridge" in markdown
    assert "不要 commit" in markdown
    assert "claude_report.md" in markdown


def test_codex_block_requires_review_only_and_output_file():
    markdown = generate_prompt_markdown("需求描述")
    assert "只做 Review，不可修改程式碼" in markdown
    assert "codex_review.md" in markdown


def test_next_step_tells_single_next_ai_and_forbids_parallel_steps():
    markdown = generate_prompt_markdown("需求描述")
    assert "ChatGPT" in markdown
    assert "不要同時執行多個角色的工作" in markdown


def test_blank_requirement_raises():
    with pytest.raises(BlankRequirementError):
        generate_prompt_markdown("   ")


def test_empty_requirement_raises():
    with pytest.raises(BlankRequirementError):
        generate_prompt_markdown("")


def test_cli_prints_markdown_to_stdout():
    result = subprocess.run(
        [sys.executable, str(CLI_PATH), "我要新增登入功能"],
        capture_output=True,
        text=True,
        check=True,
    )
    assert "# AI 協作 Prompt" in result.stdout
    assert "我要新增登入功能" in result.stdout


def test_cli_reads_from_stdin_when_no_arguments():
    result = subprocess.run(
        [sys.executable, str(CLI_PATH)],
        input="我要新增登入功能",
        capture_output=True,
        text=True,
        check=True,
    )
    assert "# AI 協作 Prompt" in result.stdout
    assert "我要新增登入功能" in result.stdout


def test_cli_blank_requirement_exits_nonzero():
    result = subprocess.run(
        [sys.executable, str(CLI_PATH), "   "],
        capture_output=True,
        text=True,
    )
    assert result.returncode != 0
    assert "ERROR" in result.stderr
