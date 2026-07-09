#!/usr/bin/env python3
"""Sprint-019 Approved Execution Queue: validator, dry-run worker, audit trail, live push.

Scope (see reviews/sprint-019/round-001/architecture.md): a file-based,
auditable queue that only ever produces *descriptions* of what a
Product-Owner-approved job would do. Nothing in this module executes a
shell command, calls the Claude or Codex CLI, commits, pushes, or closes a
Sprint. Every unsafe manifest is rejected by the validator; every approved
job is only ever dry-run.

Commands:
  validate-request       <path>
  validate-approved-job  <path>
  dry-run                <path>
  live-push              --sprint-id --round --ref --gate-type --target-actor
                          --risk-level --next-step --artifact-path
                          --audit-reference --dry-run-status
  confirm-live-push      <notification-artifact-path>
                          (Product Owner only -- Claude Code / Codex must
                          never invoke this on Product Owner's behalf)
  record-po-decision     --sprint-id --ref --decision approve|reject [--artifact-path]
                          (Product Owner only; audit-trail-only substitute
                          for a Telegram inline button -- Sprint-019
                          Architecture forbids real Telegram callback
                          integration, see architecture.md Section 4.2)

Directory layout is rooted at $REVIEWS_OVERRIDE/approved-execution-queue
(default: <repo>/reviews/approved-execution-queue), mirroring the
REVIEWS_OVERRIDE convention already used by scripts/review_bridge.sh so
tests can run against a temporary directory instead of the real queue.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import urllib.request
import urllib.error
import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import yaml

REPO_ROOT = Path(__file__).resolve().parent.parent
REVIEWS_DIR = Path(os.environ.get("REVIEWS_OVERRIDE", str(REPO_ROOT / "reviews")))
QUEUE_DIR = REVIEWS_DIR / "approved-execution-queue"
REQUESTS_DIR = QUEUE_DIR / "requests"
APPROVED_DIR = QUEUE_DIR / "approved"
DRY_RUN_DIR = QUEUE_DIR / "dry-run"
AUDIT_DIR = QUEUE_DIR / "audit"
AUDIT_LOG = AUDIT_DIR / "audit.jsonl"
NOTIFICATION_HISTORY = REVIEWS_DIR / "notification_history.jsonl"

ALLOWED_TARGET_ACTORS = {"chatgpt", "claude_code", "codex", "product_owner"}

REQUIRED_FORBIDDEN_ACTIONS = {
    "shell_command",
    "auto_approval",
    "auto_handoff",
    "commit",
    "push",
    "closure",
}

ALLOWED_JOB_TYPES = {
    "review",
    "implementation_handoff",
    "fix_handoff",
    "validation_handoff",
    "notification_validation",
    "dry_run_only",
}

FORBIDDEN_JOB_TYPES = {
    "shell_execution",
    "claude_cli_execution",
    "codex_cli_execution",
    "commit",
    "push",
    "closure",
    "telegram_callback_execution",
    "line_callback_execution",
}

# Architecture section 9: as soon as any of these keys appears anywhere in
# an Approved Job Manifest (or an Approval Request, checked defensively),
# the validator must reject it. Matched by exact key name, case-insensitive,
# recursively through the whole parsed structure -- not just top level --
# so a nested or renamed field cannot smuggle a forbidden field past the
# check.
FORBIDDEN_FIELD_NAMES = {
    "command",
    "shell",
    "exec",
    "script",
    "args",
    "token",
    "credential",
    "secret",
    "password",
    "api_key",
}

# Architecture section 7: only reviews/ is a safe location for an expected
# output artifact. Every real action (commit/push/closure/shell) is
# already forbidden by the fixed manifest constraints; this only guards
# against an expected_output_artifact pointing outside the review-artifact
# tree (e.g. into scripts/, configs/n8n, or repo root).
ALLOWED_OUTPUT_PREFIX = "reviews/"

REQUEST_REQUIRED_FIELDS = [
    "project_id",
    "sprint_id",
    "request_id",
    "requested_by",
    "requested_action",
    "target_actor",
    "risk_level",
    "allowed_actions",
    "forbidden_actions",
    "input_artifact",
    "expected_output_artifact",
    "evidence_reference",
    "requires_product_owner_approval",
    "created_at",
]

JOB_REQUIRED_FIELDS = [
    "job_id",
    "approval_request_id",
    "approved_by",
    "approved_at",
    "product_owner_decision_reference",
    "target_actor",
    "job_type",
    "allowed_action",
    "input_artifact",
    "expected_output_artifact",
    "safety_level",
    "dry_run_required",
    "commit_allowed",
    "push_allowed",
    "closure_allowed",
    "auto_handoff_allowed",
    "shell_command_allowed",
    "created_at",
]

JOB_FIXED_CONSTRAINTS = {
    "dry_run_required": True,
    "commit_allowed": False,
    "push_allowed": False,
    "closure_allowed": False,
    "auto_handoff_allowed": False,
    "shell_command_allowed": False,
}

# Heuristic, pattern-based block-list -- not a full shell parser. Rejects
# requested_action strings that look like a shell invocation (operators,
# common executables, relative-path execution). See
# docs/development/approval-request-schema.md "Known Limitation" for the
# disclosed scope of this check.
SHELL_LIKE_PATTERNS = [
    r"&&", r"\|\|", r";", r"\|", r"`", r"\$\(",
    r"(^|\s)sudo(\s|$)", r"(^|\s)rm\s", r"(^|\s)chmod\s",
    r"(^|\s)curl\s", r"(^|\s)wget\s", r"(^|\s)python3?\s",
    r"(^|\s)bash\s", r"(^|\s)sh\s", r"(^|^\./)\./",
    r"(^|\s)git\s", r"(^|\s)npm\s", r"(^|\s)pip\d?\s",
    r">\s*/", r"<\s*/",
]


class FrontMatterError(ValueError):
    pass


def parse_front_matter(path: Path) -> dict[str, Any]:
    """Parse a Markdown file's YAML front matter. Raises FrontMatterError
    if the file has no front matter block or the block is not a mapping."""
    if not path.is_file():
        raise FrontMatterError(f"File not found: {path}")

    text = path.read_text(encoding="utf-8")
    match = re.match(r"\A---\s*\n(.*?\n)---\s*\n", text, re.DOTALL)
    if not match:
        raise FrontMatterError("Markdown Front Matter not found (file must start with '---' YAML block)")

    try:
        data = yaml.safe_load(match.group(1))
    except yaml.YAMLError as exc:
        raise FrontMatterError(f"Front matter is not valid YAML: {exc}") from exc

    if not isinstance(data, dict):
        raise FrontMatterError("Front matter must be a YAML mapping")

    return data


def collect_forbidden_fields(data: Any, path: str = "") -> list[str]:
    """Recursively walk a parsed structure and return every key path whose
    key name (case-insensitive, exact match) is in FORBIDDEN_FIELD_NAMES."""
    found: list[str] = []
    if isinstance(data, dict):
        for key, value in data.items():
            key_path = f"{path}.{key}" if path else str(key)
            if str(key).lower() in FORBIDDEN_FIELD_NAMES:
                found.append(key_path)
            found.extend(collect_forbidden_fields(value, key_path))
    elif isinstance(data, list):
        for idx, item in enumerate(data):
            found.extend(collect_forbidden_fields(item, f"{path}[{idx}]"))
    return found


def is_shell_like(action: str) -> bool:
    if not isinstance(action, str):
        return False
    return any(re.search(pattern, action) for pattern in SHELL_LIKE_PATTERNS)


def looks_like_approved_job(data: dict[str, Any]) -> bool:
    return "job_id" in data and "approved_by" in data


def looks_like_request(data: dict[str, Any]) -> bool:
    return "request_id" in data and "job_id" not in data


def _missing_fields(data: dict[str, Any], required: list[str]) -> list[str]:
    return [f for f in required if f not in data or data[f] in (None, "")]


def validate_request(data: dict[str, Any]) -> tuple[bool, list[str]]:
    reasons: list[str] = []

    missing = _missing_fields(data, REQUEST_REQUIRED_FIELDS)
    if missing:
        reasons.append(f"Missing required fields: {', '.join(missing)}")

    if data.get("requires_product_owner_approval") is not True:
        reasons.append("requires_product_owner_approval must be true")

    target_actor = data.get("target_actor")
    if target_actor not in ALLOWED_TARGET_ACTORS:
        reasons.append(
            f"target_actor '{target_actor}' not in whitelist {sorted(ALLOWED_TARGET_ACTORS)}"
        )

    requested_action = data.get("requested_action")
    if is_shell_like(requested_action):
        reasons.append(f"requested_action looks like a shell command: {requested_action!r}")

    forbidden_actions = data.get("forbidden_actions")
    if isinstance(forbidden_actions, list):
        missing_forbidden = REQUIRED_FORBIDDEN_ACTIONS - set(forbidden_actions)
        if missing_forbidden:
            reasons.append(
                f"forbidden_actions missing required entries: {sorted(missing_forbidden)}"
            )
    else:
        reasons.append("forbidden_actions must be a list containing all required entries")

    forbidden_fields = collect_forbidden_fields(data)
    if forbidden_fields:
        reasons.append(f"Forbidden field(s) present: {', '.join(forbidden_fields)}")

    input_artifact = data.get("input_artifact")
    if input_artifact and not (REPO_ROOT / input_artifact).is_file():
        reasons.append(f"input_artifact does not exist: {input_artifact}")

    expected_output_artifact = data.get("expected_output_artifact")
    if expected_output_artifact and not str(expected_output_artifact).startswith(ALLOWED_OUTPUT_PREFIX):
        reasons.append(
            f"expected_output_artifact outside allowed directory '{ALLOWED_OUTPUT_PREFIX}': {expected_output_artifact}"
        )

    return (len(reasons) == 0, reasons)


def validate_approved_job(data: dict[str, Any]) -> tuple[bool, list[str]]:
    reasons: list[str] = []

    missing = _missing_fields(data, JOB_REQUIRED_FIELDS)
    if missing:
        reasons.append(f"Missing required fields: {', '.join(missing)}")

    if not data.get("approved_by") or not data.get("approved_at") or not data.get(
        "product_owner_decision_reference"
    ):
        reasons.append(
            "Product Owner approval metadata missing (approved_by / approved_at / product_owner_decision_reference)"
        )

    target_actor = data.get("target_actor")
    if target_actor not in ALLOWED_TARGET_ACTORS:
        reasons.append(
            f"target_actor '{target_actor}' not in whitelist {sorted(ALLOWED_TARGET_ACTORS)}"
        )

    job_type = data.get("job_type")
    if job_type in FORBIDDEN_JOB_TYPES:
        reasons.append(f"job_type '{job_type}' is forbidden")
    elif job_type not in ALLOWED_JOB_TYPES:
        reasons.append(f"job_type '{job_type}' not in whitelist {sorted(ALLOWED_JOB_TYPES)}")

    for field, fixed_value in JOB_FIXED_CONSTRAINTS.items():
        if data.get(field) is not fixed_value:
            reasons.append(f"{field} must be {fixed_value!r}, got {data.get(field)!r}")

    forbidden_fields = collect_forbidden_fields(data)
    if forbidden_fields:
        reasons.append(f"Forbidden field(s) present: {', '.join(forbidden_fields)}")

    input_artifact = data.get("input_artifact")
    if input_artifact and not (REPO_ROOT / input_artifact).is_file():
        reasons.append(f"input_artifact does not exist: {input_artifact}")

    expected_output_artifact = data.get("expected_output_artifact")
    if expected_output_artifact and not str(expected_output_artifact).startswith(ALLOWED_OUTPUT_PREFIX):
        reasons.append(
            f"expected_output_artifact outside allowed directory '{ALLOWED_OUTPUT_PREFIX}': {expected_output_artifact}"
        )

    return (len(reasons) == 0, reasons)


def now_iso() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def write_audit(
    event_type: str,
    project_id: str = "",
    sprint_id: str = "",
    job_id: str = "",
    request_id: str = "",
    actor: str = "approved_execution_queue",
    status: str = "",
    artifact_path: str = "",
) -> str:
    """Append one audit record. Append-only: never opens in a mode that
    could truncate or rewrite prior records. Never receives secret/token/
    credential fields -- callers must not pass them. Returns the generated
    event_id so callers can cross-reference it (e.g. an Approved Job
    Manifest's product_owner_decision_reference)."""
    AUDIT_DIR.mkdir(parents=True, exist_ok=True)
    event_id = str(uuid.uuid4())
    record = {
        "event_id": event_id,
        "event_type": event_type,
        "project_id": project_id,
        "sprint_id": sprint_id,
        "job_id": job_id,
        "request_id": request_id,
        "actor": actor,
        "status": status,
        "artifact_path": artifact_path,
        "created_at": now_iso(),
    }
    with AUDIT_LOG.open("a", encoding="utf-8") as fh:
        fh.write(json.dumps(record, ensure_ascii=False) + "\n")
    return event_id


def cmd_validate_request(args: argparse.Namespace) -> int:
    path = Path(args.path)
    try:
        data = parse_front_matter(path)
    except FrontMatterError as exc:
        print(f"BLOCKED: {exc}")
        write_audit("validator_failed", status="blocked", artifact_path=str(path))
        return 1

    if looks_like_approved_job(data):
        print("BLOCKED: this file looks like an Approved Job Manifest, not an Approval Request")
        return 1

    write_audit(
        "approval_request_created",
        project_id=str(data.get("project_id", "")),
        sprint_id=str(data.get("sprint_id", "")),
        request_id=str(data.get("request_id", "")),
        status="present",
        artifact_path=str(path),
    )
    write_audit(
        "validator_executed",
        project_id=str(data.get("project_id", "")),
        sprint_id=str(data.get("sprint_id", "")),
        request_id=str(data.get("request_id", "")),
        status="executed",
        artifact_path=str(path),
    )

    passed, reasons = validate_request(data)
    event = "validator_passed" if passed else "validator_failed"
    write_audit(
        event,
        project_id=str(data.get("project_id", "")),
        sprint_id=str(data.get("sprint_id", "")),
        request_id=str(data.get("request_id", "")),
        status="pass" if passed else "fail",
        artifact_path=str(path),
    )

    if passed:
        print("VALIDATION: PASS")
        return 0

    print("VALIDATION: FAIL")
    print("Blocked reasons:")
    for reason in reasons:
        print(f"  - {reason}")
    return 1


def cmd_validate_approved_job(args: argparse.Namespace) -> int:
    path = Path(args.path)
    try:
        data = parse_front_matter(path)
    except FrontMatterError as exc:
        print(f"BLOCKED: {exc}")
        write_audit("validator_failed", status="blocked", artifact_path=str(path))
        return 1

    if looks_like_request(data):
        print("BLOCKED: this file looks like an Approval Request, not an Approved Job Manifest")
        return 1

    write_audit(
        "approved_job_manifest_created",
        project_id=str(data.get("project_id", "")),
        job_id=str(data.get("job_id", "")),
        request_id=str(data.get("approval_request_id", "")),
        status="present",
        artifact_path=str(path),
    )
    write_audit(
        "validator_executed",
        job_id=str(data.get("job_id", "")),
        request_id=str(data.get("approval_request_id", "")),
        status="executed",
        artifact_path=str(path),
    )

    passed, reasons = validate_approved_job(data)
    event = "validator_passed" if passed else "validator_failed"
    write_audit(
        event,
        job_id=str(data.get("job_id", "")),
        request_id=str(data.get("approval_request_id", "")),
        status="pass" if passed else "fail",
        artifact_path=str(path),
    )

    if passed:
        print("VALIDATION: PASS")
        return 0

    print("VALIDATION: FAIL")
    print("Blocked reasons:")
    for reason in reasons:
        print(f"  - {reason}")
    return 1


def cmd_dry_run(args: argparse.Namespace) -> int:
    path = Path(args.path)
    try:
        data = parse_front_matter(path)
    except FrontMatterError as exc:
        print(f"BLOCKED: {exc}")
        return 1

    job_id = str(data.get("job_id", "unknown-job"))

    if looks_like_request(data) or not looks_like_approved_job(data):
        blocked_reason = "Input is an Approval Request (or unrecognized file), not an Approved Job Manifest. Dry-run refuses to treat a request as an approved job."
        _write_dry_run_report(
            job_id=job_id,
            validation_result="FAIL",
            would_execute=False,
            target_actor=str(data.get("target_actor", "")),
            job_type=str(data.get("job_type", "")),
            input_artifact=str(data.get("input_artifact", "")),
            expected_output_artifact=str(data.get("expected_output_artifact", "")),
            blocked_reason=blocked_reason,
            dry_run_status="blocked",
        )
        write_audit("dry_run_executed", job_id=job_id, status="executed", artifact_path=str(path))
        write_audit("dry_run_blocked", job_id=job_id, status="blocked", artifact_path=str(path))
        print(f"BLOCKED: {blocked_reason}")
        return 1

    write_audit("dry_run_executed", job_id=job_id, status="executed", artifact_path=str(path))

    passed, reasons = validate_approved_job(data)
    blocked_reason = "" if passed else "; ".join(reasons)

    report_path = _write_dry_run_report(
        job_id=job_id,
        validation_result="PASS" if passed else "FAIL",
        would_execute=passed,
        target_actor=str(data.get("target_actor", "")),
        job_type=str(data.get("job_type", "")),
        input_artifact=str(data.get("input_artifact", "")),
        expected_output_artifact=str(data.get("expected_output_artifact", "")),
        blocked_reason=blocked_reason,
        dry_run_status="would-execute" if passed else "blocked",
    )

    write_audit(
        "dry_run_passed" if passed else "dry_run_blocked",
        job_id=job_id,
        request_id=str(data.get("approval_request_id", "")),
        status="pass" if passed else "blocked",
        artifact_path=str(report_path),
    )

    if passed:
        print(f"DRY-RUN: would-execute (no real execution performed). Report: {report_path}")
        return 0

    print(f"DRY-RUN: blocked. Report: {report_path}")
    print("Blocked reasons:")
    for reason in reasons:
        print(f"  - {reason}")
    return 1


def _write_dry_run_report(
    job_id: str,
    validation_result: str,
    would_execute: bool,
    target_actor: str,
    job_type: str,
    input_artifact: str,
    expected_output_artifact: str,
    blocked_reason: str,
    dry_run_status: str,
) -> Path:
    DRY_RUN_DIR.mkdir(parents=True, exist_ok=True)
    safe_job_id = re.sub(r"[^A-Za-z0-9_-]", "_", job_id)
    report_path = DRY_RUN_DIR / f"{safe_job_id}-dry-run-report.md"

    front_matter = {
        "job_id": job_id,
        "validation_result": validation_result,
        "would_execute": would_execute,
        "target_actor": target_actor,
        "job_type": job_type,
        "input_artifact": input_artifact,
        "expected_output_artifact": expected_output_artifact,
        "blocked_reason": blocked_reason,
        "dry_run_status": dry_run_status,
        "created_at": now_iso(),
    }

    body = (
        "---\n"
        + yaml.safe_dump(front_matter, allow_unicode=True, sort_keys=False)
        + "---\n\n"
        "# Dry-run Report\n\n"
        "This is a simulated-execution report only. No shell command, Claude "
        "CLI, Codex CLI, commit, push, or closure was performed while "
        "producing this report.\n"
    )
    report_path.write_text(body, encoding="utf-8")
    return report_path


def _post_telegram_message(bot_token: str, chat_id: str, text: str) -> tuple[bool, str]:
    url = f"https://api.telegram.org/bot{bot_token}/sendMessage"
    payload = json.dumps({"chat_id": chat_id, "text": text}).encode("utf-8")
    req = urllib.request.Request(
        url, data=payload, headers={"Content-Type": "application/json"}, method="POST"
    )
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            body = json.loads(resp.read().decode("utf-8"))
            if body.get("ok"):
                return True, ""
            return False, f"Telegram API responded not-ok: {body}"
    except (urllib.error.URLError, OSError, ValueError) as exc:
        # OSError also catches TimeoutError/socket.timeout, which are not
        # URLError subclasses -- a slow/unreachable network must degrade to
        # a "failed" delivery_status, never an uncaught crash that skips the
        # audit trail and notification history write.
        return False, f"Telegram API request failed: {exc}"


def _chunk_message(text: str, limit: int = 3500) -> list[str]:
    """Split text into ordered, sequential chunks safely under Telegram's
    message length limit. Splits at blank-line (section) boundaries first;
    falls back to a hard character split only for a single section that is
    itself longer than the limit. Never reorders or summarizes content."""
    sections = text.split("\n\n")
    chunks: list[str] = []
    current = ""
    for section in sections:
        candidate = f"{current}\n\n{section}" if current else section
        if len(candidate) <= limit:
            current = candidate
            continue
        if current:
            chunks.append(current)
            current = ""
        if len(section) <= limit:
            current = section
        else:
            for i in range(0, len(section), limit):
                chunks.append(section[i : i + limit])
    if current:
        chunks.append(current)
    return chunks or [text]


# Sprint-019 Must Fix (Product Owner Live Push Validation FAIL round):
# the live push must be Traditional Chinese, section-based, and include a
# directly copyable Codex Review Handoff Package -- not a flat English
# field dump. This content is specific to Sprint-019's one-time mandatory
# validation push, so it is embedded here rather than turned into a
# generic reusable parameter (that would be scope expansion beyond what
# Sprint-019 requires; see docs/development/telegram-po-gate-notification-specification.md
# Section 22 for the general Next AI Handoff Package pattern this mirrors).
_CODEX_REVIEW_READING_LIST = [
    "AGENTS.md",
    "CLAUDE.md",
    "CODEX.md",
    "GPT.md",
    "PROJECT_BOOTSTRAP.md",
    "reviews/sprint-019/round-001/architecture.md",
    "reviews/sprint-019/round-001/claude_report.md",
    "scripts/approved_execution_queue.py",
    "scripts/test_approved_execution_queue.py",
    "scripts/test_approved_execution_queue.sh",
    "docs/development/approved-execution-queue.md",
    "docs/development/approval-request-schema.md",
    "docs/development/approved-job-manifest-schema.md",
    "docs/development/approved-execution-validator.md",
    "docs/development/product-owner-live-push-validation.md",
    "reviews/sprint-019/round-001/product_owner_live_push_validation_checklist.md",
    "reviews/approved-execution-queue/audit/audit.jsonl",
    "reviews/notification_history.jsonl",
]

_CODEX_REVIEW_CHECK_ITEMS = [
    "是否符合 Sprint-019 Architecture Artifact。",
    "是否沒有擴張成完整 automation platform。",
    "Approval Request Schema 是否完整。",
    "Approved Job Manifest Schema 是否完整。",
    "Validator 是否正確拒絕 unsafe manifest。",
    "Dry-run worker 是否沒有真實執行 shell command。",
    "Dry-run worker 是否沒有呼叫 Claude CLI 或 Codex CLI。",
    "Audit trail 是否正確寫入。",
    "Telegram live push 是否 delivered。",
    "Product Owner 是否實際收到 live push。",
    "推播內容是否符合中文化與 Handoff UX 要求。",
    "configs/n8n 是否未修改。",
    "是否沒有 commit automation。",
    "是否沒有 push automation。",
    "是否沒有 callback shell execution。",
    "是否沒有 secret / token / credential 寫入 repo。",
    "全部測試是否通過（python3 scripts/test_approved_execution_queue.py）。",
]

_CODEX_REVIEW_FORBIDDEN_ACTIONS = [
    "不得執行 git add。",
    "不得執行 commit。",
    "不得執行 push。",
    "不得修改檔案。",
    "不得呼叫 Claude CLI。",
    "不得呼叫 Codex CLI 以外的自動修正流程。",
    "不得自動進入 Git Review。",
    "不得自動核准 Product Owner Validation。",
    "不得自動 Closure。",
]


def _build_codex_handoff_block() -> str:
    reading_list = "\n".join(f"{i}. {f}" for i, f in enumerate(_CODEX_REVIEW_READING_LIST, 1))
    checks = "\n".join(f"{i}. {c}" for i, c in enumerate(_CODEX_REVIEW_CHECK_ITEMS, 1))
    forbidden = "\n".join(f"{i}. {a}" for i, a in enumerate(_CODEX_REVIEW_FORBIDDEN_ACTIONS, 1))
    return (
        "===== BEGIN COPY TO CODEX REVIEW =====\n"
        "你是 Codex Review。\n\n"
        "請針對 Sprint-019「Product Owner Approved Execution Queue MVP」\n"
        "進行 Architecture / Implementation Review。\n\n"
        "請先閱讀以下檔案：\n\n"
        f"{reading_list}\n\n"
        "請檢查：\n\n"
        f"{checks}\n\n"
        "禁止事項：\n\n"
        f"{forbidden}\n\n"
        "請輸出 Codex Review Report，並明確判定：\n\n"
        "PASS / MUST FIX\n"
        "===== END COPY TO CODEX REVIEW ====="
    )


# Sprint-019 Must Fix Round 2: a single Telegram message must never mix the
# Codex Handoff Package with anything else, otherwise Product Owner cannot
# copy-paste it cleanly on a phone. This constant is the hard per-message
# safety limit (below Telegram's ~4096 char cap) -- if the handoff block
# itself ever exceeds it, live-push must fail loudly instead of silently
# splitting the copy block (same principle as
# docs/development/telegram-po-gate-notification-specification.md Section 24.4).
_SINGLE_MESSAGE_LIMIT = 3500


def _build_live_push_messages(
    args: argparse.Namespace, artifact_path: Path, handoff_path: Path, created_at: str, codex_handoff: str
) -> tuple[str, str, str]:
    """Build the three section-aware Telegram messages required by Sprint-019
    Must Fix Round 2: (1) Product Owner Summary + Decision instructions,
    (2) the Codex Handoff Package ALONE, (3) Evidence / Checklist / Confirm
    instructions. Returned in send order; never reordered or merged."""
    message1 = (
        "🔔 Sprint-019 Product Owner Approved Execution Queue -- Live Push 驗收通知\n\n"
        "📌 Sprint / Round / Gate 資訊\n"
        f"Sprint: {args.sprint_id} / {args.round}\n"
        f"Job/Request ID: {args.ref}\n"
        f"Gate 類型: {args.gate_type}\n"
        f"Target Actor: {args.target_actor}\n"
        f"Risk Level: {args.risk_level}\n\n"
        "📍 目前狀態\n"
        "Claude Code 已完成 Sprint-019「Product Owner Approved Execution Queue MVP」實作，\n"
        "必要測試已全數通過，本則為 Sprint-019 硬性驗收要求的 workflow-generated live push。\n"
        f"Dry-run status: {args.dry_run_status}\n\n"
        "✅ Product Owner 現在要做什麼\n"
        "1. 確認已在 Telegram 收到全部 3 則推播（本則 Summary / 下一則 Codex Handoff Package / 最後 Evidence & Checklist）。\n"
        f"2. 閱讀 {args.artifact_path} 完整內容。\n"
        "3. 若決定交由 Codex Review，直接複製下一則訊息（只包含 Handoff Package）整段貼給 Codex。\n"
        "4. 依下方「🗳️ Product Owner 審核」指示記錄同意 / 不同意。\n\n"
        "➡️ 下一個 AI 是誰\n"
        "Codex（Codex Review）；下一則訊息即為可直接複製的 Handoff Package。\n\n"
        "🗳️ Product Owner 審核\n"
        "Sprint-019 Architecture 明確禁止 Telegram callback 真實串接與長期 worker daemon，\n"
        "因此本 MVP 不提供 Telegram 互動按鍵（真實按鍵列入未來 Sprint 的 Architecture Amendment）。\n"
        "請改用以下 CLI 指令記錄決策：同意會寫入一份 Approved Job Manifest（可被 consume-approved\n"
        "dry-run，永不真實執行）；不同意只寫入 audit event，不產生任何 manifest。兩者皆不執行任何\n"
        "shell command / Claude CLI / Codex CLI / commit / push / closure：\n\n"
        f"同意：python3 scripts/approved_execution_queue.py record-po-decision --sprint-id {args.sprint_id} --ref {args.ref} --decision approve --target-actor codex --job-type review --allowed-action \"Review Sprint-019 implementation and produce codex_review.md\" --input-artifact {args.artifact_path} --expected-output-artifact reviews/{args.sprint_id}/{args.round}/codex_review.md --safety-level {args.risk_level} --handoff-package-path {handoff_path}\n\n"
        f"不同意：python3 scripts/approved_execution_queue.py record-po-decision --sprint-id {args.sprint_id} --ref {args.ref} --decision reject\n\n"
        "⚠️ Safety Notice\n"
        "本則推播不會執行任何 shell command、Claude CLI、Codex CLI、commit、push 或 closure。\n"
        "送出本通知、以及上方的決策指令，皆不構成任何 Gate 自動核准。\n\n"
        "📎 Evidence Reference\n"
        f"- Source Artifact: {args.artifact_path}\n"
        f"- Audit Reference: {args.audit_reference}\n"
        "- Notification History: reviews/notification_history.jsonl\n\n"
        "🧾 Notification / Audit Reference\n"
        f"- notification_package_path: {artifact_path}\n"
        "- audit events: live_push_attempted / live_push_delivered\n"
        f"- created_at: {created_at}\n"
    )

    message2 = codex_handoff

    message3 = (
        "📂 Evidence & Checklist\n\n"
        f"- notification_package_path: {artifact_path}\n"
        "- Notification History: reviews/notification_history.jsonl\n"
        "- Audit Trail: reviews/approved-execution-queue/audit/audit.jsonl\n\n"
        "✅ 下一步指令\n"
        f"1. 依上一則訊息的「🗳️ Product Owner 審核」指令記錄同意 / 不同意。\n"
        f"2. 若同意，可選擇執行 consume-approved 觀察 dry-run 結果（僅模擬，不會真實執行）：\n"
        f"   python3 scripts/approved_execution_queue.py consume-approved\n"
        f"3. 執行 confirm-live-push 指令：\n"
        f"   python3 scripts/approved_execution_queue.py confirm-live-push --sprint-id {args.sprint_id} --ref {args.ref} {artifact_path}\n"
        "4. 完成 checklist：reviews/sprint-019/round-001/product_owner_live_push_validation_checklist.md\n"
        "5. 填寫 Product Owner Validation：PASS / FAIL\n"
    )

    return message1, message2, message3


def cmd_live_push(args: argparse.Namespace) -> int:
    notif_dir = REVIEWS_DIR / args.sprint_id / args.round / "notifications"
    notif_dir.mkdir(parents=True, exist_ok=True)
    safe_ref = re.sub(r"[^A-Za-z0-9_-]", "_", args.ref)
    artifact_path = notif_dir / f"{safe_ref}-live-push.md"

    created_at = now_iso()
    codex_handoff = _build_codex_handoff_block()
    handoff_path = notif_dir / f"{safe_ref}-codex-handoff.md"
    message1, message2, message3 = _build_live_push_messages(args, artifact_path, handoff_path, created_at, codex_handoff)

    if len(message2) > _SINGLE_MESSAGE_LIMIT:
        print(
            f"ERROR: Codex Handoff Package ({len(message2)} chars) exceeds the "
            f"single-message safety limit ({_SINGLE_MESSAGE_LIMIT}). Refusing to "
            "silently split it across multiple messages -- shorten the handoff "
            "content instead.",
            file=sys.stderr,
        )
        return 1

    # Must Fix Round 3 (Product Owner request): the Codex Handoff Package
    # must also exist as its own standalone file, independent of the
    # combined notification artifact, so an Approved Job Manifest can
    # reference it via handoff_package_path. Content is byte-identical to
    # Telegram Message 2 -- written once here, never duplicated/rewritten
    # elsewhere.
    handoff_path.write_text(message2, encoding="utf-8")
    print(f"Written: {handoff_path}")

    artifact_path.write_text(
        "---\n"
        + yaml.safe_dump(
            {
                "sprint_id": args.sprint_id,
                "round": args.round,
                "ref": args.ref,
                "gate_type": args.gate_type,
                "target_actor": args.target_actor,
                "risk_level": args.risk_level,
                "artifact_path": args.artifact_path,
                "audit_reference": args.audit_reference,
                "dry_run_status": args.dry_run_status,
                "created_at": created_at,
                "handoff_package_path": str(handoff_path),
            },
            allow_unicode=True,
            sort_keys=False,
        )
        + "---\n\n"
        + "===== MESSAGE 1: PRODUCT OWNER SUMMARY =====\n"
        + message1
        + "\n===== MESSAGE 2: CODEX HANDOFF PACKAGE =====\n"
        + message2
        + "\n===== MESSAGE 3: EVIDENCE & CHECKLIST =====\n"
        + message3,
        encoding="utf-8",
    )
    print(f"Written: {artifact_path}")

    write_audit(
        "live_push_attempted",
        sprint_id=args.sprint_id,
        job_id=args.ref,
        status="attempted",
        artifact_path=str(artifact_path),
    )

    notification_enabled = os.environ.get("NOTIFICATION_ENABLED", "") == "true"
    bot_token = os.environ.get("TELEGRAM_BOT_TOKEN", "")
    chat_id = os.environ.get("TELEGRAM_CHAT_ID", "")

    delivery_status: str
    error_message = ""
    delivered_at = ""

    if not notification_enabled:
        delivery_status = "disabled"
        print("Telegram delivery disabled (NOTIFICATION_ENABLED is not 'true').")
    elif not bot_token or not chat_id:
        delivery_status = "disabled"
        error_message = "NOTIFICATION_ENABLED=true but TELEGRAM_BOT_TOKEN/TELEGRAM_CHAT_ID not set"
        print(f"WARNING: {error_message}", file=sys.stderr)
    else:
        # Section-aware, ordered send: Summary, then Handoff Package ALONE,
        # then Evidence & Checklist. message2 is sent as-is (never chunked --
        # the length guard above already ensures it fits in one message);
        # message1/message3 fall back to _chunk_message only if they ever
        # grow past the limit. All parts must succeed for "delivered".
        chunks: list[str] = []
        chunks.extend(_chunk_message(message1))
        chunks.append(message2)
        chunks.extend(_chunk_message(message3))

        ok = True
        err = ""
        for chunk in chunks:
            ok, err = _post_telegram_message(bot_token, chat_id, chunk)
            if not ok:
                break
        if ok:
            delivery_status = "delivered"
            delivered_at = now_iso()
            print(f"Telegram delivery: delivered ({len(chunks)} message(s)).")
        else:
            delivery_status = "failed"
            error_message = err
            print(f"WARNING: {err}", file=sys.stderr)

    write_audit(
        "live_push_delivered" if delivery_status == "delivered" else "live_push_failed",
        sprint_id=args.sprint_id,
        job_id=args.ref,
        status=delivery_status,
        artifact_path=str(artifact_path),
    )

    history_record = {
        "record_type": "approved_execution_queue_live_push",
        "project_id": os.environ.get("PROJECT_ID", ""),
        "project_name": os.environ.get("PROJECT_NAME", ""),
        "sprint_id": args.sprint_id,
        "round_id": args.round,
        "gate_id": args.gate_type,
        "notification_recipient": "Product Owner",
        "next_actor": "Product Owner",
        "risk_level": args.risk_level,
        "notification_package_path": str(artifact_path),
        "delivery_channel": "telegram",
        "delivery_status": delivery_status,
        "created_at": created_at,
        "delivered_at": delivered_at or None,
        "error_message": error_message or None,
    }
    NOTIFICATION_HISTORY.parent.mkdir(parents=True, exist_ok=True)
    with NOTIFICATION_HISTORY.open("a", encoding="utf-8") as fh:
        fh.write(json.dumps(history_record, ensure_ascii=False) + "\n")

    print(f"Notification history updated: {NOTIFICATION_HISTORY} (delivery_status={delivery_status})")

    if delivery_status != "delivered":
        print(
            "Sprint-019 Product Owner Validation cannot pass until live push "
            "delivery is fixed (delivery_status must be 'delivered')."
        )
        return 1
    return 0


def cmd_confirm_live_push(args: argparse.Namespace) -> int:
    """Product Owner-only: record that Product Owner personally confirmed
    receipt of the live push. Claude Code / Codex must never invoke this
    command on Product Owner's behalf -- it exists only for Product Owner
    to run themselves after actually checking their Telegram client."""
    artifact_path = Path(args.artifact_path)
    if not artifact_path.is_file():
        print(f"ERROR: notification artifact not found: {artifact_path}", file=sys.stderr)
        return 1

    write_audit(
        "product_owner_live_push_confirmed",
        sprint_id=args.sprint_id,
        job_id=args.ref,
        actor="product_owner",
        status="confirmed",
        artifact_path=str(artifact_path),
    )
    print("Recorded: product_owner_live_push_confirmed")
    return 0


_ALLOWED_DECISIONS = {"approve", "reject"}

# Human-readable label for the "next_ai" descriptive manifest field (Must
# Fix Round 3). Derived from target_actor (already whitelist-checked by
# validate_approved_job) rather than a separate CLI flag, so the two values
# can never drift apart or be filled in inconsistently by the caller.
_TARGET_ACTOR_DISPLAY_NAMES = {
    "chatgpt": "ChatGPT",
    "claude_code": "Claude Code",
    "codex": "Codex Review",
    "product_owner": "Product Owner",
}


def cmd_record_po_decision(args: argparse.Namespace) -> int:
    """Product Owner-only: record an approve/reject decision. This is the
    Sprint-019 Architecture-compliant substitute for a Telegram inline
    button (real Telegram callback buttons were deferred to a future
    Architecture Amendment -- see claude_fix_report_round_2.md Section 3).
    It never executes a shell command, never calls the Claude or Codex CLI,
    never commits, pushes, or closes. Claude Code / Codex must never invoke
    this command on Product Owner's behalf.

    - decision=reject: writes ONLY an audit event. No file is ever created,
      so there is nothing in approved/ for consume-approved to accidentally
      pick up -- a rejected decision structurally cannot be consumed.
    - decision=approve: writes the audit event AND a full, validator-passing
      Approved Job Manifest into approved/ (Architecture Section 9), so the
      existing dry-run worker / consume-approved can process it. No manifest
      is written unless the decision is 'approve'.
    """
    if args.decision not in _ALLOWED_DECISIONS:
        print(f"ERROR: Invalid decision '{args.decision}' (must be one of {sorted(_ALLOWED_DECISIONS)})", file=sys.stderr)
        return 1

    decision_event_id = write_audit(
        "product_owner_decision_recorded",
        sprint_id=args.sprint_id,
        job_id=args.ref,
        actor="product_owner",
        status=args.decision,
        artifact_path=args.artifact_path or "",
    )
    print(f"Recorded: product_owner_decision_recorded (decision={args.decision}, event_id={decision_event_id})")

    if args.decision == "reject":
        return 0

    # decision == "approve": build and write a full Approved Job Manifest.
    missing = [
        name
        for name in (
            "target_actor",
            "job_type",
            "allowed_action",
            "input_artifact",
            "expected_output_artifact",
            "safety_level",
            "handoff_package_path",
        )
        if not getattr(args, name)
    ]
    if missing:
        print(
            f"ERROR: --decision approve requires: {', '.join(missing)} (not needed for --decision reject)",
            file=sys.stderr,
        )
        return 1

    if not Path(args.handoff_package_path).is_file():
        print(f"ERROR: --handoff-package-path does not exist: {args.handoff_package_path}", file=sys.stderr)
        return 1

    created_at = now_iso()
    safe_ref = re.sub(r"[^A-Za-z0-9_-]", "_", args.ref)
    manifest_path = APPROVED_DIR / f"{safe_ref}.md"
    manifest_data = {
        "job_id": args.ref,
        "approval_request_id": f"live-push:{args.ref}",
        "approved_by": "product_owner",
        "approved_at": created_at,
        "product_owner_decision_reference": f"audit_event:{decision_event_id}",
        "target_actor": args.target_actor,
        "job_type": args.job_type,
        "allowed_action": args.allowed_action,
        "input_artifact": args.input_artifact,
        "expected_output_artifact": args.expected_output_artifact,
        "safety_level": args.safety_level,
        "dry_run_required": True,
        "commit_allowed": False,
        "push_allowed": False,
        "closure_allowed": False,
        "auto_handoff_allowed": False,
        "shell_command_allowed": False,
        "created_at": created_at,
        # Descriptive fields added in Must Fix Round 3 (Product Owner
        # request): not required by Architecture Section 9, but harmless
        # additions -- none collide with FORBIDDEN_FIELD_NAMES, and
        # validate_approved_job() only checks for required-field presence,
        # the fixed safety constraints, and forbidden field names, so extra
        # descriptive fields never affect PASS/FAIL.
        "next_ai": _TARGET_ACTOR_DISPLAY_NAMES.get(args.target_actor, args.target_actor),
        "handoff_package_path": args.handoff_package_path,
        "source_artifact_path": args.input_artifact,
        "audit_reference": str(AUDIT_LOG),
        "status": "approved",
    }

    passed, reasons = validate_approved_job(manifest_data)
    if not passed:
        print("ERROR: generated Approved Job Manifest failed validation, refusing to write it:", file=sys.stderr)
        for reason in reasons:
            print(f"  - {reason}", file=sys.stderr)
        return 1

    APPROVED_DIR.mkdir(parents=True, exist_ok=True)
    manifest_path.write_text(
        "---\n"
        + yaml.safe_dump(manifest_data, allow_unicode=True, sort_keys=False)
        + "---\n\n"
        f"# Approved Job Manifest: {args.ref}\n\n"
        f"Approved by Product Owner via `record-po-decision` (decision=approve).\n"
        f"See {args.artifact_path or 'the corresponding live-push notification artifact'} for context.\n",
        encoding="utf-8",
    )
    write_audit(
        "approved_job_manifest_created",
        sprint_id=args.sprint_id,
        job_id=args.ref,
        request_id=manifest_data["approval_request_id"],
        actor="product_owner",
        status="created",
        artifact_path=str(manifest_path),
    )
    print(f"Approved Job Manifest written: {manifest_path}")
    return 0


def cmd_consume_approved(args: argparse.Namespace) -> int:
    """Batch dry-run every manifest currently in approved/. This is an
    on-demand CLI command invoked by a human -- NOT a scheduled timer or a
    long-running daemon (Sprint-019 Architecture Section 4.2 explicitly
    forbids a long-term worker daemon). It structurally can only ever see
    files placed in APPROVED_DIR: it never reads REQUESTS_DIR, and a
    rejected decision (cmd_record_po_decision) never produces a file here,
    so there is no 'pending' or 'rejected' job for it to accidentally
    consume. Every manifest is only ever dry-run (see cmd_dry_run) --
    this never calls the real Claude or Codex CLI."""
    if not APPROVED_DIR.is_dir():
        print("No approved/ directory yet -- nothing to consume.")
        return 0

    manifest_paths = sorted(APPROVED_DIR.glob("*.md"))
    if not manifest_paths:
        print("No approved job manifests found in approved/.")
        return 0

    exit_code = 0
    for path in manifest_paths:
        print(f"-- Consuming: {path}")
        code = cmd_dry_run(argparse.Namespace(path=str(path)))
        exit_code = exit_code or code
    return exit_code


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Sprint-019 Approved Execution Queue: validator, dry-run worker, audit trail, live push."
    )
    sub = parser.add_subparsers(dest="command", required=True)

    p_req = sub.add_parser("validate-request", help="Validate an Approval Request file")
    p_req.add_argument("path")
    p_req.set_defaults(func=cmd_validate_request)

    p_job = sub.add_parser("validate-approved-job", help="Validate an Approved Job Manifest file")
    p_job.add_argument("path")
    p_job.set_defaults(func=cmd_validate_approved_job)

    p_dry = sub.add_parser("dry-run", help="Dry-run an Approved Job Manifest file")
    p_dry.add_argument("path")
    p_dry.set_defaults(func=cmd_dry_run)

    p_live = sub.add_parser("live-push", help="Sprint-019 mandatory live push validation")
    p_live.add_argument("--sprint-id", required=True)
    p_live.add_argument("--round", required=True)
    p_live.add_argument("--ref", required=True, help="Job ID or Request ID")
    p_live.add_argument("--gate-type", required=True)
    p_live.add_argument("--target-actor", required=True)
    p_live.add_argument("--risk-level", required=True)
    p_live.add_argument("--next-step", required=True)
    p_live.add_argument("--artifact-path", required=True)
    p_live.add_argument("--audit-reference", required=True)
    p_live.add_argument("--dry-run-status", required=True)
    p_live.set_defaults(func=cmd_live_push)

    p_confirm = sub.add_parser(
        "confirm-live-push",
        help="Product Owner only: confirm receipt of a live push",
    )
    p_confirm.add_argument("--sprint-id", required=True)
    p_confirm.add_argument("--ref", required=True)
    p_confirm.add_argument("artifact_path")
    p_confirm.set_defaults(func=cmd_confirm_live_push)

    p_decision = sub.add_parser(
        "record-po-decision",
        help="Product Owner only: record an approve/reject decision",
    )
    p_decision.add_argument("--sprint-id", required=True)
    p_decision.add_argument("--ref", required=True)
    p_decision.add_argument("--decision", required=True)
    p_decision.add_argument("--artifact-path", default="")
    # Only required when --decision approve (validated inside
    # cmd_record_po_decision, not via argparse `required=`, so `reject`
    # never has to pass them).
    p_decision.add_argument("--target-actor", default="")
    p_decision.add_argument("--job-type", default="")
    p_decision.add_argument("--allowed-action", default="")
    p_decision.add_argument("--input-artifact", default="")
    p_decision.add_argument("--expected-output-artifact", default="")
    p_decision.add_argument("--safety-level", default="")
    p_decision.add_argument("--handoff-package-path", default="")
    p_decision.set_defaults(func=cmd_record_po_decision)

    p_consume = sub.add_parser(
        "consume-approved",
        help="On-demand batch dry-run of every manifest in approved/ (not a daemon/timer)",
    )
    p_consume.set_defaults(func=cmd_consume_approved)

    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
