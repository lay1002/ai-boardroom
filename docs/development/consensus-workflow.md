# Consensus Workflow

## Development Principles Authority

This document operates under `docs/development/development-principles.md`, the AI Workspace Development Constitution.

Development Principles v2.0, the canonical Definition of Done, and the Sprint Retrospective / Product Owner Decision requirements are defined there as the single source of truth. This document does not redefine them; it defines the Review Bridge gate mechanics and artifact requirements below, which are unchanged by this reference.

## Purpose

This document defines the only approved AI collaboration workflow for this workspace.

The goal is to ensure that no Sprint is committed until ChatGPT defines the architecture, Claude Code completes the implementation, Codex completes the review, Review Bridge produces consensus, and Product Owner explicitly approves the commit.

This workflow is the single source of truth for AI collaboration gates. Older workflow documents may describe supporting checklists, but they must not override this document.

## Unique Workflow

Every Sprint must follow this exact order:

```text
ChatGPT Architecture
↓
Claude Code Implementation
↓
Codex Review
↓
Claude Reply
↓
Codex Final Review
↓
Review Bridge Consensus
↓
final_consensus.md
↓
Product Owner Gate
↓
Commit
```

No step may be skipped. No step may be reordered. No AI agent may replace another role unless Product Owner explicitly updates this document.

## Roles

### Product Owner

Owns Sprint scope, final decision, Product Owner Gate, and commit approval.

Product Owner is the only role allowed to approve moving from `final_consensus.md` to Commit.

### ChatGPT

Acts as Chief Product Architect.

Responsible for:

- Architecture
- Boundaries
- Scope
- Acceptance Criteria
- API Contract direction
- Sprint specification

ChatGPT does not implement runtime code in this workflow.

### Claude Code

Claude Code is the only Implementation AI in this workflow.

Responsible for:

- Implementing the approved Architecture and Specification
- Keeping changes within Sprint scope
- Preserving API contracts unless explicitly approved
- Running required tests
- Producing `claude_report.md`
- Producing `claude_reply.md` when Codex raises issues

Claude Code must not:

- Act as Reviewer AI
- Rewrite the approved architecture
- Expand scope
- Auto-commit

### Codex

Codex is the only Reviewer AI in this workflow.

Responsible for:

- Reviewing Claude Code implementation
- Reviewing architecture compliance
- Reviewing API contract risk
- Reviewing scope control
- Reviewing tests and known limitations
- Producing `codex_review.md`
- Producing `codex_final_review.md` after Claude Reply

Codex must not:

- Act as Implementation AI
- Implement fixes during this workflow
- Rewrite the approved architecture
- Expand scope
- Auto-commit

### Review Bridge

Review Bridge is a development gate coordinator.

Responsible for:

- Preparing Codex review prompts
- Collecting Claude and Codex review artifacts
- Producing `consensus_report.md`
- Producing `final_consensus.md` only after consensus PASS

Review Bridge is not V3 Runtime.

Review Bridge must not:

- Auto-fix code
- Auto-run another Claude/Codex loop
- Auto-commit
- Override Product Owner Gate

## Required Artifact Structure

The first review round must use this exact directory:

```text
reviews/<sprint-id>/round-001/
```

The first round must use these exact file names:

```text
reviews/<sprint-id>/round-001/architecture.md
reviews/<sprint-id>/round-001/claude_report.md
reviews/<sprint-id>/round-001/codex_prompt.md
reviews/<sprint-id>/round-001/codex_review.md
reviews/<sprint-id>/round-001/claude_reply.md
reviews/<sprint-id>/round-001/codex_final_review.md
reviews/<sprint-id>/round-001/consensus_report.md
reviews/<sprint-id>/round-001/final_consensus.md
```

No alternative file names are allowed.

The following alias patterns are not allowed in the canonical workflow:

- `implementation_report.md`
- `review_prompt.md`
- `review_report.md`
- `implementation_reply.md`
- Any `or` file naming rule

## Additional Rounds

If a second review round is required, it must use this exact directory:

```text
reviews/<sprint-id>/round-002/
```

Additional rounds continue by incrementing the round number:

```text
reviews/<sprint-id>/round-003/
reviews/<sprint-id>/round-004/
```

## Sprint Types

Each Sprint has a type that determines which artifacts are required.

### A. Implementation Sprint

Used for modifying source code.

Required artifacts:

```text
reviews/<sprint-id>/round-<nnn>/
- architecture.md
- claude_report.md
- codex_prompt.md
- codex_review.md
- claude_reply.md
- codex_final_review.md
- consensus_report.md
- final_consensus.md
```

### B. Documentation Sprint

Used for modifying documentation or architecture documents without changing source code.

Required artifacts:

```text
reviews/<sprint-id>/round-<nnn>/
- reviewed_document.md  (or explicitly recorded reviewed_document_path)
- claude_report.md
- codex_prompt.md
- codex_review.md
- claude_reply.md
- codex_final_review.md
- consensus_report.md
- final_consensus.md
```

### Artifact Differences

- Documentation Sprint does NOT require `architecture.md`.
- The document under review (`reviewed_document.md` or `reviewed_document_path`) serves as the architecture artifact for Documentation Sprints.
- Review Bridge must record the Sprint Type in both `consensus_report.md` and `final_consensus.md`.
- Review Bridge must determine which artifacts are missing based on Sprint Type.

## Fill Artifacts Step

After `skeleton` creates the round files, the files are placeholders only.

Before running Review Bridge `consensus`, the responsible roles must replace placeholder content with actual Sprint content and review results.

For an Implementation Sprint, the following files must contain actual content before `consensus` runs:

```text
architecture.md
claude_report.md
codex_review.md
claude_reply.md
codex_final_review.md
```

`codex_prompt.md` is a review prompt artifact and must not be treated as a replacement for actual Claude or Codex review results.

Placeholder files are not valid consensus input. If deterministic markers are missing because placeholders were not replaced, Review Bridge must produce `Gate Status: FAIL`.

`check` validates required input artifact presence only. It does not prove that placeholder content has been replaced or that deterministic markers will pass consensus.

## Review Round Naming

Each round must use the same fixed file names defined above.

Artifacts from previous rounds must not be overwritten.

## final_consensus.md Rule

`final_consensus.md` may exist only in the final round directory.

Examples:

```text
reviews/<sprint-id>/round-001/final_consensus.md
reviews/<sprint-id>/round-002/final_consensus.md
```

If `round-002` is required, then `round-001/final_consensus.md` must not be treated as valid for Commit Gate.

The valid commit artifact is always:

```text
reviews/<sprint-id>/<final-round>/final_consensus.md
```

No `final_consensus.md`, no Product Owner Gate.

No `final_consensus.md`, no commit.

## Consensus Stop Rule

Discusssion may stop only when all conditions are true:

1. No unresolved Architecture Conflict.
2. No unresolved Must Fix.
3. Acceptance Criteria are satisfied.
4. No scope expansion occurred.
5. Claude Reply has addressed Codex Review issues.
6. Codex Final Review is PASS.
7. `consensus_report.md` says `Gate Status: PASS`.
8. Open Questions are either zero or explicitly accepted by Product Owner.
9. Product Owner agrees to close the Sprint.

If any condition fails:

- Review Bridge must not produce `final_consensus.md`.
- Product Owner Gate must not proceed.
- Commit Gate must not proceed.
- The Sprint must continue with another manual round or explicit Product Owner decision.

## Review Bridge Consensus

Review Bridge may produce `consensus_report.md` after the required round artifacts exist.

The required artifacts depend on the Sprint Type:

- **Implementation Sprint**: `architecture.md`, `claude_report.md`, `codex_prompt.md`, `codex_review.md`, `claude_reply.md`, `codex_final_review.md`.
- **Documentation Sprint**: `reviewed_document.md` (or `reviewed_document_path`), `claude_report.md`, `codex_prompt.md`, `codex_review.md`, `claude_reply.md`, `codex_final_review.md`.

`consensus_report.md` must clearly state one of:

```text
Gate Status: PASS
Gate Status: FAIL
```

Review Bridge must record the Sprint Type in `consensus_report.md`.

Review Bridge may produce `final_consensus.md` only when the latest round `consensus_report.md` says:

```text
Gate Status: PASS
```

If the latest round `consensus_report.md` is missing or does not say `Gate Status: PASS`, Review Bridge must stop.

Review Bridge must record the Sprint Type in `final_consensus.md`.

## Commit Gate

A Sprint may be committed only when all conditions are true:

1. The latest round is the final round.
2. The latest round contains `final_consensus.md`.
3. `final_consensus.md` says `Consensus: PASS`.
4. `final_consensus.md` says `Consensus Stop Rule: PASS`.
5. Product Owner approves the commit after reviewing `final_consensus.md`.
6. Commit scope is clean and limited to the approved Sprint.

No final consensus means no commit.

No Product Owner approval means no commit.

No AI agent may auto-commit.

## Manual Gate Policy

This workflow is Human-in-the-loop.

Do not use:

- Auto Commit
- Auto Claude Loop
- Auto Codex Loop
- Background Auto Merge
- Automatic continuation to the next round without Product Owner visibility

The Product Owner remains the final gate.

## Handoff Package Standard (Sprint-017)

Every formal Claude / Codex Handoff Package — whether generated by Review Bridge (`handoff_package.md`, see `scripts/review_bridge.sh`'s `write_handoff_package_claude_to_codex` / `write_handoff_package_codex_to_claude`) or authored directly by Product Owner in a chat-based Implementation/Must-Fix instruction — MUST open with the full, standardized reading list:

```text
請閱讀：

- PROJECT_BOOTSTRAP.md
- AGENTS.md
- GPT.md
- CLAUDE.md
- CODEX.md
- docs/development/development-workflow.md
- docs/development/consensus-workflow.md
- docs/development/n8n-claude-done-notification.md
- docs/development/n8n-codex-review-done-notification.md
- scripts/review_bridge.sh

若上述文件不存在，請在 report 中記錄為 Missing Context，不要自行建立或補寫。
```

A shortened reading list (e.g. only 3–5 files) MUST NOT be used in a formal Handoff Package. If a listed file does not exist, the recipient records it as Missing Context in their report (see Report Context Completeness Check below) rather than inventing a replacement or silently skipping it.

Every formal Handoff Package MUST also include a Telegram Notification block:

```text
Telegram Notification:

- Should notify Product Owner: YES / NO
- gate_id: <actual_gate_id>
- sprint_id: <sprint-id>
- round_id: <round-id>
- artifact_path: <path>
- Expected Telegram result: Product Owner receives copyable Handoff Package for next actor
```

`gate_id` MUST be one of the 21 canonical gate IDs in `docs/development/product-owner-gate-metadata.md` — never a placeholder or a guessed value. If the correct `gate_id` cannot be determined, this is recorded as Missing Context, not guessed. See `docs/development/telegram-po-gate-notification-specification.md` Sections 18–19 for the full notify-gate Execution Policy and the distinction between a manual chat-based handoff and a formal Telegram Gate Notification — this block never implies that Telegram has already been notified; it only states whether it *should* be, and with what parameters, for Product Owner to decide.

**Inline content, not just a path reference (Sprint-017 Must Fix Round 3)**: whenever a Handoff Package references a source artifact — whether the Sprint-010 `handoff_package.md` generated by `check`, or the Gate Notification Package generated by `notify-gate` — Product Owner must be able to read the artifact's actual content without leaving Telegram or opening the repository. A bare `請閱讀：- <path>` reference is not sufficient. See `docs/development/telegram-po-gate-notification-specification.md` Section 20 for the concrete rule (inline the artifact's real content between explicit BEGIN/END markers) and its safe-chunking behavior for content too long for a single Telegram message.

**Next AI Handoff Package, so Product Owner never has to return to ChatGPT (Sprint-017 Must Fix Round 5)**: when approving a Product Owner Gate leads directly to another AI actor's next task (e.g. approving `product_owner_validation_approval` leads to a Codex Git Review), the formal Telegram Gate Notification MUST include a copy-pasteable Handoff Package for that next AI actor, not just a description of what comes next. See `docs/development/telegram-po-gate-notification-specification.md` Section 22 for the required content (full reading list, Traditional Chinese output rule, Context Completeness Check requirement, task objective, review target, allowed/prohibited files, repository hygiene and runtime evidence exclusion checks, exact report path, and the standard restrictions against git add/commit/push, notify-gate, Telegram, and n8n JSON) and for how this section is kept visually separated from the Product Owner Summary, the Decision Options, and the Raw Artifact Evidence.

**Telegram Content Mode: full raw evidence is opt-in, not default (Sprint-017 Must Fix Round 6)**: Product Owner reported that always-inlining full Raw Artifact Evidence (Round 3–5 behavior) made the actually-copyable Next AI Handoff Package hard to use once a long artifact split the Telegram message into many pieces. `notify-gate`'s default content mode ("handoff") therefore no longer inlines full raw artifact content — it includes the Product Owner Summary, Decision Options, Next AI Handoff Package, and an Evidence Reference (paths only). Full inline content remains available on request via `TELEGRAM_CONTENT_MODE=full`. See `docs/development/telegram-po-gate-notification-specification.md` Section 23 for the three modes (`summary` / `handoff` / `full`), the fixed section order that keeps the Next AI Handoff Package contiguous and copyable, and the reminder that contract validation PASS is still never equivalent to live delivery PASS regardless of content mode.

**Next AI Handoff Package must be its own, uninterrupted Telegram message (Sprint-017 Must Fix Round 7)**: Product Owner reported that even with Round 6's default "handoff" mode, character-chunking the whole Notification Package could still land Evidence Reference or Delivery Metadata in the same Telegram message as the Next AI Handoff Package, forcing a manual search for the copy boundary before pasting into Codex or Claude Code. `notify-gate` therefore delivers section-aware, separate messages instead of one chunked stream: a Summary+Decision message, a standalone Next AI Handoff message (delimited by a fixed `===== BEGIN COPY TO <TARGET_AI> ===== / ===== END COPY TO <TARGET_AI> =====` marker and containing nothing else), an Evidence+Metadata message, and — full mode only — one or more Raw Artifact Evidence messages that always come after the handoff message, never before or inside it. If the handoff content would not fit in one uninterrupted message, `notify-gate` fails loudly rather than silently splitting it. See `docs/development/telegram-po-gate-notification-specification.md` Section 24 for the full message-order contract and the copy-boundary marker format.

## Report Context Completeness Check (Sprint-017)

The following report types MUST include a `## Context Completeness Check` section:

- Claude Implementation Report
- Claude Must Fix Report
- Codex Review Report
- Codex Final Review Report

```markdown
## Context Completeness Check

- Full required reading list provided: PASS / FAIL
- Missing context files: None / list
- Did missing context affect implementation or review: YES / NO
- Notes:
```

These four report types are authored as prose content by Claude Code / Codex (only their placeholder skeletons are script-generated by `review_bridge.sh skeleton`, via the `TEMPLATE ONLY` marker) — this section is therefore a required authoring convention, not something Review Bridge injects automatically. Whoever writes the report is responsible for including it.

## Retrospective Flow Deviation Check (Sprint-017)

Every Sprint Retrospective / Actual Flow Report MUST additionally include a `## Flow Deviation Check` section:

```markdown
## Flow Deviation Check

- Full reading list used in all formal Handoff Packages: PASS / FAIL
- Any shortened reading list used: YES / NO
- Context Completeness Check present in Claude / Codex reports: PASS / FAIL
- Missing context files recorded: YES / NO / N/A
- Telegram Notification block present in formal Handoff Packages: PASS / FAIL
- notify-gate expected: YES / NO
- notify-gate executed by Product Owner: YES / NO
- Telegram notification received: YES / NO / NOT VERIFIED
- Manual handoff used instead of Telegram notification: YES / NO
- Manual Gate skipped: YES / NO
- Review scope drift occurred: YES / NO
- unrelated dirty / untracked files mixed into Sprint scope: YES / NO
- Notes:
```

**Relationship to `docs/development/development-principles.md`**: the canonical Sprint Retrospective structure (Objective / Root Cause / Lessons Learned / Process Improvement / Backlog / Product Owner Decision) is defined by Development Principles v2.0 Principle 6, Section 3 "Rule 6 Mandatory Template" — the Development Constitution, which has higher authority than this document (see this document's own Development Principles Authority section) and is not modified by Sprint-017. This section adds `## Flow Deviation Check` as an **additional required section** for every Retrospective going forward, layered on top of the Constitution's template rather than replacing or renumbering it. Per Development Principles Principle 7 ("Process Improvement Never Goes Backwards"), this addition must be preserved or strengthened by future Sprints. Whether to formally fold `## Flow Deviation Check` into the Constitution's own Section 3 template text is left to Product Owner's discretion in a future dedicated Sprint that explicitly touches `development-principles.md` — Sprint-017 does not modify that file.

## Product Owner Gate Operation UX (Sprint-018)

Sprint-013–017's Telegram / Handoff capabilities are now formally adopted into the ongoing development flow. `docs/development/product-owner-gate-operation-ux.md` is the entry-point document for how Product Owner actually operates the Gate notification system day-to-day (the operating loop, which Content Mode to use when, and pointers to the authoritative specs). `reviews/sprint-018/round-001/gate_notification_matrix.md` defines the concrete notify-gate operating contract (Notification purpose, Decision options, Next AI Handoff Package requirement, Target AI, copy boundary, stop condition, recommended Content Mode) for 14 of the 21 canonical Product Owner Gates — selected as the highest-judgment, highest-risk, or phase-starting Gates, plus `claude_must_fix_report_acceptance` added in Must Fix Round 2 as the Claude Fix Report Ready checkpoint (symmetric to `claude_implementation_report_acceptance`); the remaining 7 canonical Gates are unaffected and still fully defined in `docs/development/product-owner-gate-metadata.md`.

## Claude Report Completion Notification Step (Sprint-018 Must Fix Round 5; unconditional invocation fixed in Round 6)

After Claude Code finishes writing a Claude Implementation Report (`claude_report.md`) or a Claude Fix Report (`claude_fix_report*.md`) and has run the Sprint's required tests, completing that report is not finished until Claude Code has also performed the Claude Report Completion Notification Step.

**Round 5's original design required all 5 env vars to be present before invoking `push-claude-report` at all, skipping the call entirely otherwise. Product Owner's live-flow validation found this insufficient: because the Telegram-specific vars were never actually set in any real session, the command was never once invoked, `reviews/notification_history.jsonl` never gained a record, and no push artifact was ever produced — Product Owner had nothing verifiable to check, only Claude's own prose claim of "not attempted."**

**Round 6 fixes this: Claude Code unconditionally runs**

```bash
PROJECT_ID=ai-workspace PROJECT_NAME="AI Workspace" \
  ./scripts/review_bridge.sh push-claude-report <sprint-id> <round> <implementation|fix> [report-path]
```

**as the final step before ending the turn, every time, with no pre-check gating whether the call happens.** `PROJECT_ID`/`PROJECT_NAME` are non-secret project labels (the repo's established real convention), supplied directly so the command never dies for lack of them. Whatever Telegram-specific variables (`NOTIFICATION_ENABLED`, `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID`) already exist in the local shell environment pass through naturally — Claude Code never reads, prints, logs, or otherwise surfaces their values, and never asks Product Owner to paste them into the chat. The command itself (unchanged since Round 5) determines the outcome: `delivered` if Telegram vars are present and delivery succeeds, `disabled` if they are absent, `failed` if delivery itself errors — and in every case, writes a real `reviews/notification_history.jsonl` record and a real push artifact under `reviews/<sprint>/round-<round>/notifications/`, which is what makes the step verifiable independent of Claude's own report text.

This remains a narrow, Product-Owner-authorized exception scoped to `push-claude-report` only — it does not change the `notify-gate` Execution Policy (`docs/development/telegram-po-gate-notification-specification.md` Sections 18–19), which remains exclusively a human-triggered command; Claude Code still must never run `notify-gate`. See `docs/development/telegram-po-gate-notification-specification.md` Section 27 for the full rule, the safety boundaries it does not change (no auto Codex call, no auto Gate approval, no auto commit/push, no `configs/n8n/*.json` changes, no Telegram token ever requested from or shown by Claude Code, opt-in Telegram delivery unchanged), the required `## Telegram Push Status` report section format, and Section 27.7's Product Owner Live Flow Validation acceptance criterion.

## Independent Review Handoff Authority (Sprint-018)

**Claude Implementation Report may be an input to a Codex Review Handoff, but Claude Code must never single-handedly decide the Codex Review's scope, checklist, Required Reading, or forbidden actions.** A Codex Review Handoff must be composed from the approved canonical template — `reviews/sprint-018/round-001/codex_review_handoff_policy.md` Section 3 (Review Independence Requirement, Git Diff/Git Status Check, Scope/Out of Scope Check, Runtime Evidence Exclusion Check) plus the existing `docs/development/git-review-checklist.md` / `docs/development/execution-permission-policy.md` where applicable — never a checklist Claude invents or narrows on its own inside `claude_report.md`. This prevents the implementer from ever being the sole author of the standard its own work will be judged against.

## Review Bridge Self-Modification Safety Rule (Sprint-018)

If a Sprint modifies Review Bridge itself — `scripts/review_bridge.sh`, a Handoff Package Template, `notify-gate`, the Telegram renderer, or copy-boundary generation — that Sprint's Codex Review must not rely solely on the newly-modified Review Bridge's own output as evidence. Codex must additionally inspect the Architecture directly, the fixed checklist directly, the actual source diff, and the test evidence's own assertion logic (not just "tests are green"), since a bug in the modified tool could make its own output look self-consistent while still being wrong. See `reviews/sprint-018/round-001/codex_review_handoff_policy.md` Section 4 for the full trigger conditions and required checks.

## Scope Control

All AI participants must obey:

- Do not expand Sprint scope.
- Do not change API contracts unless explicitly approved.
- Do not introduce new engines, providers, memory, workflow runtime, queue, dashboard, or plugin system unless the Sprint explicitly requires it.
- Prefer minimal change.
- Prefer configuration over code.
- Preserve Platform First principles.

## PASS Criteria

A Sprint is PASS only if:

- ChatGPT Architecture is followed.
- Claude Code implementation satisfies Acceptance Criteria.
- Codex Review has no unresolved Must Fix.
- Claude Reply addresses Codex issues.
- Codex Final Review is PASS.
- Latest `consensus_report.md` says `Gate Status: PASS`.
- Latest round `final_consensus.md` exists.
- Consensus Stop Rule is PASS.
- Product Owner approves.

## FAIL Criteria

A Sprint is FAIL if:

- Required artifacts are missing for the recorded Sprint Type.
- Artifact names are not exact.
- Artifact paths are not exact.
- Sprint Type is not recorded in `consensus_report.md` or `final_consensus.md`.
- Architecture conflicts remain unresolved.
- Must Fix items remain unresolved.
- Scope was expanded without approval.
- Codex Final Review is not PASS.
- Latest `consensus_report.md` is missing.
- Latest `consensus_report.md` does not say `Gate Status: PASS`.
- Latest round `final_consensus.md` is missing.
- Product Owner does not approve.
