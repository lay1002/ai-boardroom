# Sprint-013 Architecture — Generic Telegram Notification Runtime Reconnect

## 0. Provenance Note

This artifact records the Sprint-013 decision as communicated directly by Product Owner in the Implementation request ("Product Owner 已核准 Sprint-013 Architecture Artifact"). It is a formalization of that decision at the canonical path required by `docs/development/consensus-workflow.md`, not an independently originated Architecture design by Claude Code. This is the Sprint's sole implementation input.

## 1. Sprint Information

Sprint ID: `sprint-013`

Sprint Name: `Generic Telegram Notification Runtime Reconnect`

Sprint Type: Implementation

Architecture Status: APPROVED (Product Owner, communicated directly)

## 2. Objective

Reconnect a generic Telegram notification runtime into `scripts/review_bridge.sh` so that any Sprint, in any project, can produce a copyable Handoff/Notification Package and push it to Product Owner before the Product Owner Manual Gate — while preventing duplicate pushes, supporting arbitrary Sprint/project identifiers, and never auto-advancing the workflow.

## 3. Runtime Pipeline

```text
Workflow Event
    ↓
Detect Artifact
    ↓
Generate Notification Package
    ↓
Calculate Artifact Hash
    ↓
Generate Deduplication Key
    ↓
Check Notification History
    ↓
Send Telegram Message
    ↓
Write Notification History
```

## 4. In Scope

- Workflow Event → Notification Package runtime wiring.
- Notification Package generator (Markdown artifact).
- Telegram Delivery Adapter (direct Telegram Bot API, not routed through n8n).
- Deduplication mechanism.
- Notification History append-only writer (`reviews/notification_history.jsonl`).
- A minimal `scripts/review_bridge.sh notify` command.
- Minimal tests and minimal documentation.

## 5. Event Whitelist

Exactly these 8 event types are accepted; any other value is rejected:

```text
claude_implementation_done
codex_review_done
claude_should_fix_done
codex_final_review_done
git_review_done
commit_done
push_done
retrospective_done
```

## 6. Required Parameters

```text
project_id
project_name
sprint_id
round_id
event_type
artifact_path
target_actor
delivery_channel
```

`delivery_channel` is fixed to `telegram` in Sprint-013 (no other channel is implemented). `project_id` / `project_name` are supplied via environment variables (`PROJECT_ID`, `PROJECT_NAME`) rather than hardcoded, so the same tooling works for any project. `target_actor` is derived deterministically from `event_type` (see `claude_report.md`-equivalent implementation report for the mapping table) rather than requiring a separate CLI argument, since the Sprint's own event list already implies one primary actor per event.

No value below may be hardcoded in the implementation:

```text
AI Workspace
ai-workspace
sprint-013
round-001
Telegram chat ID
Telegram bot token
GitHub repo name
```

## 7. CLI

```bash
scripts/review_bridge.sh notify <sprint_id> <round> <event_type> <artifact_path>
```

`<round>` follows the existing `validate_round` convention used by `check` / `consensus` / `finalize` (bare number, e.g. `001`); the `round_id` field recorded in the Notification Package and history is rendered as `round-<round>` for consistency with the rest of this specification's examples.

## 8. Notification Package

Path:

```text
reviews/<sprint-id>/round-<round-id>/notifications/<event_type>.md
```

Required sections: Project, Sprint, Round, Event Type, Target Actor, Source Artifact, Artifact Hash, Next Product Owner Action, Copyable Handoff Package, Delivery Metadata.

The Notification Package is the sole content source for Telegram delivery. The Telegram adapter must not originate, rewrite, condense, or reinterpret content — it sends the package's own text, unmodified.

## 9. Deduplication

Deduplication Key:

```text
<project_id>/<sprint_id>/<round_id>/<event_type>/<artifact_path>/<artifact_hash>
```

Rules:

1. If a history record with this exact key exists with `delivery_status = delivered`, do not push again.
2. If the artifact content changes (new `artifact_hash`), a new key is produced and a new push is allowed.
3. A duplicate is not a failure; it is recorded/reported as `skipped_duplicate`.
4. No Database is used for deduplication.
5. Deduplication is computed by scanning `reviews/notification_history.jsonl`.

## 10. Notification History

Append-only JSON Lines file, no Database:

```text
reviews/notification_history.jsonl
```

Each record: `project_id`, `project_name`, `sprint_id`, `round_id`, `event_type`, `artifact_path`, `artifact_hash`, `notification_package_path`, `delivery_channel`, `delivery_status`, `deduplication_key`, `created_at`, `delivered_at`, `error_message`.

Allowed `delivery_status` values: `pending`, `delivered`, `skipped_duplicate`, `failed`, `disabled`.

## 11. Telegram Delivery

Configured entirely via environment variables: `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID`, `NOTIFICATION_ENABLED`, `PROJECT_ID`, `PROJECT_NAME`.

- Delivery is only attempted when `NOTIFICATION_ENABLED=true`.
- When not `true` (or unset), no Telegram call is made, but the Notification Package is still generated and history is still written (`delivery_status = disabled`).
- No token or chat ID may be hardcoded, written to the repo, written to the Notification Package, written to Notification History, or printed to any log output.
- Missing configuration must fail safely (no crash, no silent mis-reporting as delivered).
- A dry-run / test mode must be supported for environments where a real Telegram send is not appropriate; dry-run maps to `delivery_status = pending`.

## 12. Failure Handling

| Condition | Behavior |
|---|---|
| Missing artifact | No Telegram send; command exits non-zero; clear error printed; a `failed` history record is written when feasible. |
| Missing Telegram config | No Telegram send; Notification Package still generated if artifact exists; history records `disabled`; command does not report `delivered`. |
| Duplicate notification | No Telegram send; history records/command reports `skipped_duplicate`; not treated as failure; workflow is not advanced. |
| Telegram API failure | No infinite retry; history records `failed`; Notification Package is preserved; workflow is not advanced. |

## 13. Out of Scope

Database, Queue, Redis, Worker, AI Auto Loop, automatic invocation of Claude Code or Codex, automatic Commit, automatic Push, Slack/LINE/Email channels, multi-user notification management, Web UI, Notification Center, new product features, and any redesign of the AI Workspace V1 Baseline.

Must not modify: the approved Architecture Definition itself (beyond recording it here), AI role division, Product Owner Manual Gate principles, Consensus rules, canonical artifact names, Sprint lifecycle, or the SSOT positioning of the Architecture Baseline / Operational Model / Notification Package Specification documents. Must not touch unrelated dirty/untracked files. Must not stage, commit, or push. Must not auto-invoke Codex.

## 14. Compatibility Requirements

Must not change `check`, `consensus`, `finalize`, `validate-final-consensus`, canonical artifact naming rules, existing Sprint review artifacts, or existing gate logic. The `notify` command is additive only.

## 15. Acceptance Scenarios

Scenario A (Codex Review Done), Scenario B (Artifact Changed → new hash → new push allowed), Scenario C (Missing Telegram Config → package still generated, no send, `disabled`/`failed` recorded), Scenario D (Generic Sprint — arbitrary `sprint_id`/`round_id`, no hardcoded assumption of `sprint-013`), Scenario E (Invalid Event Type → safe failure, no `delivered` status, clear error) — as specified in the Sprint-013 request. All five are exercised in `scripts/test_review_bridge.sh`.

## 16. Definition of Done

All 22 items listed in the Sprint-013 request Section 14 apply verbatim and are the acceptance bar for this Sprint; see the Implementation Report for the item-by-item compliance check.

## 17. Architecture Review Result

Not yet reviewed by Codex. Submitted for Codex Implementation Review after Claude Code implementation is complete, per `docs/development/consensus-workflow.md`.
