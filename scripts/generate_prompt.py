#!/usr/bin/env python3
"""CLI for the Prompt Generator.

Reads a requirement description from CLI arguments (or stdin if no
arguments are given) and prints the generated four-section Markdown
prompt bundle to stdout. See
`reviews/sprint-008/round-001/architecture.md`.

Usage:
    scripts/generate_prompt.py "我要新增登入功能"
    echo "我要新增登入功能" | scripts/generate_prompt.py
"""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from backend.app.engines.prompt_generator.errors import PromptGeneratorError
from backend.app.engines.prompt_generator.generator import generate_prompt_markdown


def main() -> int:
    requirement = " ".join(sys.argv[1:]) if len(sys.argv) > 1 else sys.stdin.read()

    try:
        markdown = generate_prompt_markdown(requirement)
    except PromptGeneratorError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1

    print(markdown)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
