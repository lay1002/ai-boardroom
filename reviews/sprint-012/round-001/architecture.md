# Sprint-012 Architecture — AI Workspace V1 Baseline Establishment Sprint

## 0. Provenance Note

This artifact was requested at path `reviews/sprint-012/round-001/architecture_artifact.md`. It has been created at the canonical path required by `docs/development/consensus-workflow.md` (`architecture.md`) instead, per the explicit authorization in the Sprint-012 request to adjust repo-convention naming while preserving equivalent semantics. See `claude_report.md`-equivalent reporting for this rename rationale.

This document records the Sprint-012 decision as communicated directly by Product Owner in the Implementation request. It is a formalization of that decision, not an independently originated Architecture design by Claude Code.

## 1. Sprint Information

Sprint ID: `sprint-012`

Sprint Name: `AI Workspace V1 Baseline Establishment Sprint`

Sprint Type: Documentation / Specification (no runtime code)

Architecture Status: APPROVED (Product Owner, communicated directly)

## 2. Objective

Establish the AI Workspace V1 baseline and specify a Notification Package MVP as the single source of truth (SSOT) for cross-role notifications, superseding ad-hoc per-workflow notification payloads with one consistent, artifact-first contract.

This Sprint is documentation/specification only. It defines the contract; it does not wire the contract into `scripts/review_bridge.sh` or any n8n workflow.

Sprint-012 is designated the AI Workspace V1 Final Sprint. After Sprint-012, the workspace enters Maintenance Mode as defined in `docs/development/operational-model.md`.

## 3. Required Artifacts

```text
docs/architecture/ai-workspace-v1-architecture-baseline.md
docs/development/operational-model.md
docs/development/notification-package-specification.md
reviews/sprint-012/round-001/architecture.md   (this file; canonical rename of architecture_artifact.md)
```

## 4. Core Architecture Requirements

- **Notification Package SSOT**: every notification's content originates from one artifact; delivery channels never originate content.
- **Delivery failure handling**: artifact must exist and be usable even if delivery fails.
- **Manual resend / regenerate**: supported, without side effects on workflow state.
- **Notification history**: traceable record of Event / Status / Target Actor / Created Time / Delivery Status / Artifact Path.
- **Target Actor**: exactly one of `ChatGPT`, `Claude Code`, `Codex`, `Product Owner` per package.
- **Scenario validation**: Scenario A (normal delivery) and Scenario B (delivery failure) must both be satisfiable from the specification.
- **Telegram is Delivery Channel only**: Telegram/n8n/any channel only delivers; it is never the source of notification content.
- **Artifact First**: the package artifact is authoritative; delivery is a side effect of the artifact existing.
- No Database, Queue, Runtime Engine, or AI Auto Loop introduced.
- No automatic invocation of Claude Code or Codex.
- No automatic Consensus, Commit, or Push.
- Product Owner Manual Gate is preserved in full.

Full field/enum/rule definitions are specified in `docs/development/notification-package-specification.md`, which is the SSOT for the Notification Package contract itself (this Architecture document does not duplicate it).

## 5. Notification Events In Scope

```text
architecture_review_pass
architecture_artifact_ready
claude_implementation_done
codex_review_done
po_validation_ready
git_review_pass
commit_done
push_done
```

## 6. Out of Scope

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
- Wiring this specification into `scripts/review_bridge.sh` or any `configs/n8n/*.json` (deferred to a future Implementation Sprint)

## 7. Compatibility Requirements

Must not break:

- Review Bridge (`scripts/review_bridge.sh`, `scripts/test_review_bridge.sh`) — untouched by this Sprint.
- Consensus Workflow (`docs/development/consensus-workflow.md`) — untouched by this Sprint.
- Development Principles (`docs/development/development-principles.md`) — untouched by this Sprint; this Sprint's artifacts reference it, per its own Section 0/7 authority rules.
- Existing Sprint Artifacts (`reviews/sprint-002` through `reviews/sprint-011`) — untouched by this Sprint.
- Product Owner Manual Gate — preserved; nothing in this Sprint changes gate mechanics.

## 8. Acceptance Criteria

- The four required artifacts exist with the content described in Section 4–5.
- `docs/development/notification-package-specification.md` defines all 14 required fields, the Status enum (6 values), the Target Actor enum (4 values), Delivery Rules, Manual Regenerate Requirement, Notification History Requirement, and both Scenario A/B validations.
- No source code or Review Bridge behavior is modified.
- No new Database, Queue, Runtime Engine, or AI Auto Loop is introduced.
- Existing Sprint artifacts and governance documents are unmodified.

## 9. Architecture Review Result

Not yet reviewed by Codex. This document is submitted for Codex Implementation Review after Claude Code implementation is complete, per `docs/development/consensus-workflow.md`.
