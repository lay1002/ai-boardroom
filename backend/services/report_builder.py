def build_final_report(question: str, moderator: dict) -> str:
    key_consensus = moderator.get("key_consensus", [])
    key_conflicts = moderator.get("key_conflicts", [])
    risk_flags = moderator.get("risk_flags", [])
    next_steps = moderator.get("next_steps", [])

    confidence = moderator.get("confidence")
    confidence_text = f"{int(confidence * 100)}%" if isinstance(confidence, (int, float)) else "N/A"

    report = f"""
# AI Boardroom Final Report

## Question

{question}

## Board Summary

{moderator.get("board_summary", "")}

## Key Consensus

{format_bullets(key_consensus)}

## Key Conflicts

{format_bullets(key_conflicts)}

## Risk Flags

{format_bullets(risk_flags)}

## Final Recommendation

{moderator.get("final_recommendation", "")}

## Next Steps

{format_numbered(next_steps)}

## Confidence

{confidence_text}
""".strip()

    return report


def format_bullets(items: list) -> str:
    if not items:
        return "- N/A"

    return "\n".join([f"- {item}" for item in items])


def format_numbered(items: list) -> str:
    if not items:
        return "1. N/A"

    return "\n".join([f"{index + 1}. {item}" for index, item in enumerate(items)])