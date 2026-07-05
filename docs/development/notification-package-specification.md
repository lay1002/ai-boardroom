# Notification Package Specification

> Notification Package MVP — Single Source of Truth (SSOT)

Version: 1.0 (Sprint-012)

---

## 0. Authority

This document is the **single source of truth (SSOT)** for the Notification Package contract.

It operates under `docs/development/development-principles.md` (the AI Workspace Development Constitution) and does not override it. It does not change `docs/development/consensus-workflow.md` Review Bridge gate mechanics.

This document defines the **contract only**. It is a specification, not an implementation. Wiring this contract into `scripts/review_bridge.sh` or any delivery channel (Telegram, n8n, etc.) is out of scope for Sprint-012 and is deferred to a future Implementation Sprint.

This document governs AI Workspace V1 only. It does not define AI Collaboration Engine or AI Decision Assistant runtime behavior (see `docs/architecture/ai-workspace-v1-architecture-baseline.md` Section 2, Product Boundary).

---

## 1. Core Principle: Artifact First, SSOT

A Notification Package is a **repo artifact**. Its content is authoritative.

Delivery channels (Telegram, n8n, email, or any future channel) may only **deliver** a Notification Package. They must never **originate, summarize, rewrite, or supplement** its content.

If a delivery channel is unavailable, degraded, or fails, the Notification Package artifact must still exist, and Product Owner must be able to continue the workflow using the artifact directly (see Section 8, Scenario B).

---

## 2. Notification Events

Notification Packages MUST be produced for the following events:

| Event | Meaning | Typical Target Actor |
|---|---|---|
| `architecture_review_pass` | Codex has completed Architecture Review and the result is PASS | Claude Code |
| `architecture_artifact_ready` | An Architecture artifact (`architecture.md` or equivalent) has been produced and is ready for the next role | Codex |
| `claude_implementation_done` | Claude Code has completed implementation and produced `claude_report.md` | Codex |
| `codex_review_done` | Codex has completed a review and produced `codex_review.md` or `codex_final_review.md` | Claude Code |
| `po_validation_ready` | An artifact chain is ready for Product Owner to validate (e.g. `final_consensus.md` exists) | Product Owner |
| `git_review_pass` | Git Review Gate (Gate 4, per `development-workflow.md`) has passed | Product Owner |
| `commit_done` | A commit has been made (manually, by Product Owner decision) | Product Owner |
| `push_done` | A push has been made (manually, by Product Owner decision) | Product Owner |

No other events are defined by this specification. Adding a new event requires a new Sprint Architecture decision (per Development Principle 7: Process Improvement Never Goes Backwards — this is an extension, not a regression, so it is additive and requires explicit Product Owner approval, not a silent addition).

---

## 3. Required Fields

Every Notification Package MUST contain exactly the following 14 fields:

| # | Field | Type | Description |
|---|---|---|---|
| 1 | Sprint ID | string | e.g. `sprint-012`. Matches the `reviews/<sprint-id>/` directory. |
| 2 | Round ID | string | e.g. `round-001`. Matches the `round-<nnn>/` directory. |
| 3 | Event | enum | One of the 8 events in Section 2. |
| 4 | Status | enum | One of the 6 allowed values in Section 4. |
| 5 | Target Actor | enum | Exactly one of the 4 allowed values in Section 5. |
| 6 | Created Time | timestamp | ISO 8601 timestamp of when the package was generated (or regenerated). |
| 7 | Package Version | integer | Starts at `1`; incremented by 1 on every Manual Regenerate (Section 7). Never reset. |
| 8 | Summary | text | A short, human-readable description of what happened. |
| 9 | Next Step | text | What the Target Actor should do next. |
| 10 | Copy & Paste Prompt | text (block) | A complete, self-contained prompt the Target Actor can copy directly into a new AI session. Must not depend on chat history or delivery-channel context (same requirement as Sprint-010 Handoff Package Section 8). |
| 11 | Validation Support | text | Which Scenario(s) (A and/or B, see Section 8) this package instance has been exercised against, if any; or `Not Validated` if untested. |
| 12 | Artifact Path | path | The absolute repo-relative path to the source artifact that triggered this event (e.g. `reviews/sprint-012/round-001/claude_report.md`). |
| 13 | Delivery Channel | enum/text | e.g. `Telegram`, `n8n`, `None` (not yet delivered). |
| 14 | Delivery Status | enum | One of: `NOT_ATTEMPTED`, `DELIVERED`, `FAILED`. Independent of the package's own `Status` field (see Section 6). |

A Notification Package missing any of these 14 fields is **invalid** and must not be treated as a valid SSOT record.

---

## 4. Allowed `Status` Values

Only the following six values are allowed for the `Status` field:

```text
READY
PASS
FAIL
BLOCKED
DONE
PUSHED
```

No other value may be used. `Status` describes the state of the underlying Sprint/Round event (e.g. `codex_review_done` with `Status: PASS` means the review passed; `Status: FAIL` means it did not).

---

## 5. Allowed `Target Actor` Values

Only the following four values are allowed:

```text
ChatGPT
Claude Code
Codex
Product Owner
```

Every Notification Package MUST specify **exactly one** primary Target Actor. A package must not name multiple actors as equally primary; if more than one role needs to know, additional packages should be generated (one per actor) rather than overloading a single package's Target Actor field.

---

## 6. Delivery Rules

1. **SSOT**: The Notification Package artifact is the source of truth. Telegram, n8n, or any other delivery channel may only deliver it — never originate, edit, or supplement its content.
2. **Delivery failure does not invalidate the package**: If delivery fails, the artifact must still exist on disk, and `Delivery Status` must be set to `FAILED` (not silently left as `NOT_ATTEMPTED`, and not deleted or hidden).
3. **Delivery Status is independent of Status**: A package can have `Status: PASS` (the underlying event succeeded) and `Delivery Status: FAILED` (the notification about it failed to send) at the same time. These two fields must never be conflated.
4. **Product Owner can always continue from the artifact**: Regardless of `Delivery Status`, Product Owner must be able to open the Notification Package artifact directly, read `Summary` / `Next Step` / `Copy & Paste Prompt`, and continue the workflow without needing the delivery channel to have succeeded.

---

## 7. Manual Regenerate Requirement

Notification Packages MUST support manual regeneration.

Regenerating a Notification Package:

- Increments `Package Version` by 1.
- Updates `Created Time` to the regeneration time.
- May update `Delivery Channel` / `Delivery Status` (e.g. to retry delivery).
- Must recompute `Summary`, `Next Step`, and `Copy & Paste Prompt` from the current state of the `Artifact Path` source artifact — never from a cached or previously delivered copy.

Regenerating a Notification Package MUST NOT:

- Modify Sprint/Round workflow state (e.g. must not change `consensus_report.md`, `final_consensus.md`, or any Review Bridge gate artifact).
- Re-run any implementation step.
- Automatically invoke Claude Code.
- Automatically invoke Codex.
- Automatically commit.
- Automatically push.

Regeneration is a pure, side-effect-free read-and-re-render operation over existing artifacts.

---

## 8. Notification History Requirement

Every Notification Package instance (including all regenerated versions) MUST be traceable via a history record containing at minimum:

- Event
- Status
- Target Actor
- Created Time
- Delivery Status
- Artifact Path

This specification does not require a database. History MAY be implemented as:

- A directory of versioned Notification Package artifacts (e.g. one file per `Package Version`), or
- A single append-only log-style record referencing each package version.

The exact storage mechanism is an Implementation Sprint decision, not fixed by this specification. Whichever mechanism is chosen, it must be a plain repo artifact (file(s) under `reviews/` or a similar tracked location), consistent with Development Principle 5 (Evidence Before Assumption).

---

## 9. Scenario Validation Requirements

A specification-compliant Notification Package implementation must support both scenarios below using only the fields and rules defined in this document.

### Scenario A: Normal Notification Flow

```text
Notification Package Generated
    ↓
Telegram / Delivery Channel Sent
    ↓
Product Owner Receives Notification
    ↓
Product Owner Copies Prompt
    ↓
Next AI Session Can Continue
```

Validation: `Delivery Status = DELIVERED`; `Copy & Paste Prompt` is self-contained and can be pasted into a fresh AI session with no additional context required.

### Scenario B: Delivery Failure

```text
Notification Package Generated
    ↓
Delivery Failed
    ↓
Product Owner Uses Artifact
    ↓
Prompt Can Still Be Copied
    ↓
Workflow Continues
```

Validation: `Delivery Status = FAILED`; the artifact file is still present and readable; `Copy & Paste Prompt` is unaffected by the delivery failure and can still be copied directly from the artifact file.

Both scenarios must be satisfiable **without** any change to the package's `Status`, `Summary`, or `Copy & Paste Prompt` fields — delivery outcome must never leak into or alter the notification's substantive content.

---

## 10. Minimal Notification Package Template

```markdown
# Notification Package

Sprint ID: <sprint-id>
Round ID: <round-nnn>
Event: <one of Section 2>
Status: <one of Section 4>
Target Actor: <one of Section 5>
Created Time: <ISO 8601>
Package Version: <integer, starts at 1>

## Summary

<short human-readable description>

## Next Step

<what the Target Actor should do next>

## Copy & Paste Prompt

<complete, self-contained prompt>

## Validation Support

<Scenario A / Scenario B / Not Validated>

## Artifact Path

<repo-relative path>

## Delivery Channel

<Telegram / n8n / None>

## Delivery Status

<NOT_ATTEMPTED / DELIVERED / FAILED>
```

---

## 11. Out of Scope (Sprint-012)

This specification explicitly does not include, and no future addition may be assumed without a new Sprint Architecture decision:

- Database
- Queue
- Runtime Engine
- AI Auto Loop
- Auto Consensus
- Auto Commit
- Auto Push
- Automatic invocation of Claude Code
- Automatic invocation of Codex
- Automatic Product Owner Decision
- Wiring into `scripts/review_bridge.sh` or `configs/n8n/*.json` (deferred to a future Implementation Sprint)

---

## 12. Relationship to Existing Notification Mechanisms

Sprint-010 (`docs/development/n8n-claude-done-notification.md`) and the Codex Review notification (`docs/development/n8n-codex-review-done-notification.md`) already implement a narrower, two-event notification mechanism directly inside `scripts/review_bridge.sh` (`notify_claude_report_done`, `notify_codex_review_done`), with content delivered inline in the webhook payload.

This specification generalizes that pattern to all 8 events in Section 2, with a stricter field contract and explicit Manual Regenerate / History requirements. **This specification does not replace or modify the existing Sprint-010 mechanism in Sprint-012** — no code changes are made in this Sprint. Migrating the existing mechanism to conform to this specification, if desired, is future Implementation Sprint work and must be evaluated against Development Principle 3 (Platform Last) before being undertaken.
