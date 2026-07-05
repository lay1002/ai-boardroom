# Notification Package Specification

> Notification Package MVP — Single Source of Truth (SSOT)

Version: 1.1 (Sprint-013 Must Fix — event model and field contract aligned with the `notify` runtime; SSOT conflict resolved)

---

## 0. Authority

This document is the **single source of truth (SSOT)** for the Notification Package contract.

It operates under `docs/development/development-principles.md` (the AI Workspace Development Constitution) and does not override it. It does not change `docs/development/consensus-workflow.md` Review Bridge gate mechanics.

This document defines the **contract**. As of Sprint-013, it is implemented by `scripts/review_bridge.sh notify` (Telegram delivery channel); see Section 13.

This document governs AI Workspace V1 only. It does not define AI Collaboration Engine or AI Decision Assistant runtime behavior (see `docs/architecture/ai-workspace-v1-architecture-baseline.md` Section 2, Product Boundary).

---

## 1. Core Principle: Artifact First, SSOT

A Notification Package is a **repo artifact**. Its content is authoritative.

Delivery channels (Telegram, n8n, email, or any future channel) may only **deliver** a Notification Package. They must never **originate, summarize, rewrite, or supplement** its content.

Concretely, for Telegram: the exact text of the Notification Package artifact (verbatim) is what must be transmitted. A delivery channel implementation must not separately compose, template, or otherwise render a different message body from the same underlying data — doing so is a Must Fix-level violation of this section (see Sprint-013 `codex_review.md` Must Fix 1).

If a delivery channel is unavailable, degraded, or fails, the Notification Package artifact must still exist, and Product Owner must be able to continue the workflow using the artifact directly (see Section 8, Scenario B).

---

## 2. Notification Events

Notification Packages MUST be produced for the following events. This list is the Sprint-013 `notify` runtime whitelist, adopted here as the SSOT event model (superseding the original Sprint-012 draft list, which has been retired — see Section 13):

| Event | Meaning | Notification Recipient | Next Actor |
|---|---|---|---|
| `claude_implementation_done` | Claude Code has completed implementation and produced `claude_report.md` | Product Owner | Codex |
| `codex_review_done` | Codex has completed a review and produced `codex_review.md` | Product Owner | Product Owner (see Section 5.1) |
| `claude_should_fix_done` | Claude Code has addressed Codex Should Fix items | Product Owner | Codex |
| `codex_final_review_done` | Codex has completed the final review | Product Owner | Product Owner |
| `git_review_done` | Git Review Gate has completed | Product Owner | Product Owner |
| `commit_done` | A commit has been made (manually, by Product Owner decision) | Product Owner | Product Owner |
| `push_done` | A push has been made (manually, by Product Owner decision) | Product Owner | Product Owner |
| `retrospective_done` | Sprint Retrospective has been completed | Product Owner | Product Owner |

No other events are defined by this specification. Adding a new event requires a new Sprint Architecture decision (per Development Principle 7: Process Improvement Never Goes Backwards — this is an extension, not a regression, so it is additive and requires explicit Product Owner approval, not a silent addition).

---

## 3. Required Fields

Every Notification Package MUST contain exactly the following 17 fields. This list supersedes the original Sprint-012 14-field list (see Section 13): `Target Actor` has been retired and split into `Notification Recipient` and `Next Actor` (Must Fix 2), and field names are aligned with the Sprint-013 `notify` runtime (Must Fix 4).

| # | Field | Type | Description |
|---|---|---|---|
| 1 | Project ID | string | Generic project identifier, supplied via `PROJECT_ID`. Never hardcoded to a specific project. |
| 2 | Project Name | string | Generic project display name, supplied via `PROJECT_NAME`. Never hardcoded. |
| 3 | Sprint ID | string | e.g. `sprint-013`. Matches the `reviews/<sprint-id>/` directory. Any value is valid; must not be assumed to be a specific Sprint. |
| 4 | Round ID | string | e.g. `round-001`. Matches the `round-<nnn>/` directory. |
| 5 | Event Type | enum | One of the 8 events in Section 2. |
| 6 | Notification Recipient | constant | **Always `Product Owner`.** This is who Telegram delivery is addressed to. It is never Claude Code or Codex — Telegram must never be used to notify an AI role directly, since that would bypass the Product Owner Manual Gate. |
| 7 | Next Actor | enum | One of `ChatGPT`, `Claude Code`, `Codex`, `Product Owner` — who Product Owner should hand the artifact to next, per Section 2's table. This is informational for Product Owner only; it never causes an automatic invocation of that actor. |
| 8 | Source Artifact Path | path | The repo-relative (or explicitly-provided) path to the artifact that triggered this event. |
| 9 | Artifact Hash | string | SHA-256 of the source artifact's content, used to build the Deduplication Key (Section 7). |
| 10 | Deduplication Key | string | `<project_id>/<sprint_id>/<round_id>/<event_type>/<source_artifact_path>/<artifact_hash>` (see Section 7). |
| 11 | Notification Package Path | path | The repo-relative path of this Notification Package artifact itself (self-referential). |
| 12 | Delivery Channel | enum/text | e.g. `telegram`. Sprint-013 supports `telegram` only. |
| 13 | Delivery Status | enum | The status **as of package generation time**: `pending` (delivery about to be attempted or not yet resolved). The authoritative, post-delivery-attempt outcome (`delivered` / `skipped_duplicate` / `failed` / `disabled`) is recorded in Notification History (Section 8), not mutated back into this field after the fact — this avoids the package's transmitted content differing from its on-disk content after the send (Must Fix 1). |
| 14 | Created Time | timestamp | ISO 8601 timestamp of when the package was generated. |
| 15 | Product Owner Next Action | text | What Product Owner (the recipient) should do, phrased from Product Owner's perspective — e.g. "Product Owner should forward this to Codex and request a review," never phrased as an instruction addressed to Codex or Claude Code directly. |
| 16 | Copyable Handoff Package | text (block) | A complete, self-contained prompt/summary that Product Owner can copy and forward to the `Next Actor`. Must not depend on chat history or delivery-channel context (same requirement as Sprint-010 Handoff Package Section 8). |
| 17 | Delivery Metadata | text (block) | A short block restating Delivery Channel, Deduplication Key, and Created Time, for quick reference. |

A Notification Package missing any of these 17 fields is **invalid** and must not be treated as a valid SSOT record.

Fields intentionally not carried forward from the Sprint-012 draft (`Status` enum, `Package Version`, `Validation Support`) are out of scope for this Must Fix: they would require additional judgment logic (e.g. parsing source-artifact pass/fail state, tracking regenerate version counters) beyond resolving the recipient/actor conflation and the artifact-first delivery bug. Reintroducing them is deferred to a future Sprint if Product Owner requires it.

---

## 4. Retired: `Status` Field (Sprint-012 draft)

The Sprint-012 draft `Status` enum (`READY` / `PASS` / `FAIL` / `BLOCKED` / `DONE` / `PUSHED`) is retired as of Sprint-013 (see Section 3's field list and Section 13). It required judgment about the underlying event's pass/fail outcome that the generic `notify` runtime does not compute. Reintroducing a status-of-the-underlying-event concept is deferred to a future Sprint.

---

## 5. Notification Recipient vs. Next Actor

This section resolves the recipient/actor conflation identified in Sprint-013 Must Fix 2. `Target Actor` (Sprint-012 draft, singular, ambiguous) is retired and replaced by two distinct fields (Section 3, fields 6–7):

### 5.1 Notification Recipient

**Always `Product Owner`.** Sprint-013's purpose is to notify Product Owner before the Product Owner Manual Gate. Telegram (or any future delivery channel) must never be configured to notify Claude Code or Codex directly — doing so would bypass the Manual Gate.

### 5.2 Next Actor

One of `ChatGPT`, `Claude Code`, `Codex`, `Product Owner` — per Section 2's table, this is who Product Owner should consider handing the artifact to next. It is informational content inside the package, read by Product Owner; it never triggers an automatic invocation of that actor.

For `codex_review_done`, `Next Actor` is conservatively set to `Product Owner` (not `Claude Code`), because whether the round returns to Claude Code for fixes depends on the review's outcome (Must Fix vs. no Must Fix), which the generic `notify` runtime does not parse from the artifact. The `Product Owner Next Action` field for this event explicitly states that Product Owner should read the review and decide whether to forward it to Claude Code.

A package must not name more than one primary Next Actor. If multiple roles genuinely need to act, generate one package per event/actor rather than overloading a single package.

---

## 6. Delivery Rules

1. **SSOT**: The Notification Package artifact is the source of truth. Telegram, n8n, or any other delivery channel may only deliver it — never originate, edit, or supplement its content. For Telegram specifically, the transmitted message text must be the Notification Package's own text (verbatim, split into literal chunks only if length requires it — see Section 3, `Delivery Channel`).
2. **Delivery failure does not invalidate the package**: If delivery fails, the artifact must still exist on disk, and Notification History (Section 8) must record `failed` (not silently omitted, and the artifact is not deleted or hidden).
3. **Delivery outcome is recorded in History, not by mutating the package's `Delivery Status` field after transmission**: this guarantees the artifact that was actually sent to Telegram is never retroactively different from what is later read from disk (Must Fix 1). See Section 3, field 13.
4. **Product Owner can always continue from the artifact**: Regardless of delivery outcome, Product Owner must be able to open the Notification Package artifact directly, read `Product Owner Next Action` / `Copyable Handoff Package`, and continue the workflow without needing the delivery channel to have succeeded.

---

## 7. Manual Regenerate Requirement

Notification Packages MUST support manual regeneration: re-running `notify` for the same Sprint/Round/Event/Artifact.

Regenerating a Notification Package:

- Updates `Created Time` to the regeneration time.
- Recomputes `Artifact Hash` and `Deduplication Key` from the current state of the `Source Artifact Path` — never from a cached or previously delivered copy. If the source artifact changed, the new hash produces a new Deduplication Key and a new delivery is allowed (Section 6).
- Recomputes `Product Owner Next Action` and `Copyable Handoff Package` from current data.
- May produce a different Delivery Channel/outcome on retry (recorded in Notification History, not in the package itself — Section 6).

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

Every Notification Package instance MUST be traceable via a history record containing at minimum:

- Event Type
- Delivery Status (the authoritative, post-attempt outcome: `pending` / `delivered` / `skipped_duplicate` / `failed` / `disabled`)
- Created Time (and Delivered Time, when applicable)
- Source Artifact Path
- Artifact Hash
- Deduplication Key

This specification does not require a database. History MAY be implemented as:

- A directory of versioned Notification Package artifacts, or
- A single append-only log-style record (e.g. `reviews/notification_history.jsonl`, per Sprint-013).

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

Validation: Notification History records `delivery_status = delivered` for this Deduplication Key; `Copyable Handoff Package` is self-contained and can be pasted into a fresh AI session with no additional context required.

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

Validation: Notification History records `delivery_status = failed` (or `disabled`, if configuration was missing) for this Deduplication Key; the artifact file is still present and readable; `Copyable Handoff Package` is unaffected by the delivery failure and can still be copied directly from the artifact file.

Both scenarios must be satisfiable **without** any change to the package's `Product Owner Next Action` or `Copyable Handoff Package` fields — delivery outcome never leaks into or alters the notification's substantive content; it is recorded separately in Notification History.

---

## 10. Minimal Notification Package Template

```markdown
# Notification Package

## Project ID

<project-id>

## Project Name

<project-name>

## Sprint ID

<sprint-id>

## Round ID

<round-nnn>

## Event Type

<one of Section 2>

## Notification Recipient

Product Owner

## Next Actor

<one of Section 5.2>

## Source Artifact Path

<path>

## Artifact Hash

<sha-256>

## Deduplication Key

<project-id>/<sprint-id>/<round-nnn>/<event-type>/<source-artifact-path>/<artifact-hash>

## Notification Package Path

<repo-relative path of this file>

## Delivery Channel

telegram

## Delivery Status

pending

## Created Time

<ISO 8601>

## Product Owner Next Action

<what Product Owner should do, phrased from Product Owner's perspective>

## Copyable Handoff Package

<complete, self-contained prompt/summary>

## Delivery Metadata

- Delivery Channel: telegram
- Deduplication Key: <same as above>
- Created At: <ISO 8601>
```

---

## 11. Out of Scope

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
- Multi-channel delivery (Slack, LINE, Email, etc.) — Telegram only as of Sprint-013
- Wiring into `configs/n8n/*.json` (the Sprint-013 `notify` runtime delivers directly via the Telegram Bot API, not through n8n)

---

## 12. Relationship to Existing Notification Mechanisms

Sprint-010 (`docs/development/n8n-claude-done-notification.md`) and the Codex Review notification (`docs/development/n8n-codex-review-done-notification.md`) already implement a narrower, two-event notification mechanism directly inside `scripts/review_bridge.sh` (`notify_claude_report_done`, `notify_codex_review_done`), with content delivered inline in the webhook payload.

This specification generalizes that pattern to all 8 events in Section 2, with a stricter field contract and explicit Manual Regenerate / History requirements. **This specification does not replace or modify the existing Sprint-010 mechanism in Sprint-012** — no code changes are made in this Sprint. Migrating the existing mechanism to conform to this specification, if desired, is future Implementation Sprint work and must be evaluated against Development Principle 3 (Platform Last) before being undertaken.

---

## 13. Implementation Status (Sprint-013)

`scripts/review_bridge.sh notify <sprint-id> <round> <event-type> <artifact-path>` implements a generic Notification Package runtime pipeline (Detect Artifact → Generate Notification Package → Hash → Deduplication Key → Check History → Send Telegram → Write History), delivering directly to the Telegram Bot API and writing an append-only `reviews/notification_history.jsonl`. See `reviews/sprint-013/round-001/architecture.md` for the approved Sprint-013 decision and `reviews/sprint-013/round-001/claude_report.md` for implementation details.

**SSOT conflict resolved (Sprint-013 Must Fix)**: this document's Section 2 event list and Section 3 field contract have been updated to match the `notify` runtime exactly — there is no longer a discrepancy between this SSOT and the Sprint-013 implementation. The originally-drafted Sprint-012 event list and 14-field contract (including `Status`, `Target Actor`, `Package Version`, `Validation Support`) are retired; see Sections 2–5 above for the current, authoritative definitions.
