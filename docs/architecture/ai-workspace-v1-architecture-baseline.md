# AI Workspace V1 — Architecture Baseline

Version: 1.1 (Sprint-012, Should Fix applied)

---

## 0. Authority

This document operates under `docs/development/development-principles.md` (the AI Workspace Development Constitution). It consolidates, but does not redefine or override, the Architecture established by each individual Sprint listed below. In case of any discrepancy between this summary and a Sprint's own `reviews/<sprint-id>/round-001/architecture.md` (or `reviewed_document.md`), the individual Sprint artifact is authoritative.

---

## 1. Purpose

This document declares **AI Workspace V1** as established, consolidating the capabilities built across Sprint-002 through Sprint-012, and marks Sprint-012 as the AI Workspace V1 Final Sprint. See `docs/development/operational-model.md` for what happens after this baseline (Maintenance Mode).

---

## 2. Product Boundary

This section makes the Sprint-012 Product Owner decision self-contained: **AI Workspace is a Platform, not a product.** Three distinct terms are used across this repository's governance and vision documents, and they must not be conflated:

### 2.1 AI Workspace (this baseline)

- AI Workspace is a **development / governance platform**.
- It exists to support: AI Collaboration Workflow (ChatGPT → Claude Code → Codex → Product Owner), Review Bridge, Consensus Workflow, Sprint Management, and Development Standards (`docs/development/development-principles.md`).
- AI Workspace is **not** a final product. It has no end-user-facing runtime, no Decision Engine, and no Perspective/Workflow execution of its own.
- Sprint-012 establishes AI Workspace **V1**, i.e. this baseline of development/governance capability — not a product release.

### 2.2 AI Collaboration Engine

- AI Collaboration Engine is a **possible next-stage collaboration capability** that AI Workspace could support in the future (e.g. a productized, reusable form of the ChatGPT/Claude Code/Codex collaboration pattern currently operated manually via `scripts/review_bridge.sh` and the Manual Gate).
- AI Collaboration Engine is **not equivalent to AI Workspace V1**. AI Workspace V1 is the current, manual-gated tooling baseline; AI Collaboration Engine, if ever built, would be a distinct, later capability layered on top of it.
- AI Collaboration Engine is **not part of Sprint-012's runtime scope**. No such engine, and no runtime supporting it, is implemented, proposed, or approved by this Sprint.

### 2.3 AI Decision Assistant

- AI Decision Assistant (V3, per `AGENTS.md` §0) is the **final product direction** for this workspace's output: an AI Decision Operating System with Decision Engine, Perspective Engine, Consensus Engine, Memory Engine, etc.
- AI Decision Assistant is **not** AI Workspace itself. AI Workspace is the development/governance platform used to *build* AI Decision Assistant (and anything else this repository produces); it is not the product.
- Future AI Decision Assistant work may be **supported by** AI Workspace's processes, governance, and collaboration standards (Development Principles, Manual Gate, Review Bridge), but AI Decision Assistant's runtime (Decision/Perspective/Consensus/Memory Engines) is a separate concern from AI Workspace V1 and is not established, implemented, or expanded by this Sprint.

### 2.4 Summary Table

| Term | What it is | Relationship to Sprint-012 |
|---|---|---|
| AI Workspace | Development / governance Platform | Established as V1 by this Sprint |
| AI Collaboration Engine | Possible future collaboration capability built on AI Workspace | Not implemented; not in scope |
| AI Decision Assistant | Final product direction | Not AI Workspace; may later be supported by AI Workspace's standards |

---

## 3. V1 Capability Baseline

| Capability | Established In | Summary |
|---|---|---|
| Template Engine | Sprint-002 | Loader / Validator / Renderer for YAML Template Definitions (`backend/app/engines/template/`), Boardroom as first sample template. |
| Review Bridge Automation | Sprint-004, Sprint-005 | `scripts/review_bridge.sh`: `init` / `skeleton` / `check` / `consensus` / `finalize` / `validate-final-consensus`, deterministic marker-based gate evaluation. |
| Prompt Generator | Sprint-008 | `backend/app/engines/prompt_generator/`: deterministic ChatGPT/Claude Code/Codex prompt bundle generator. |
| Workflow 1 — Claude Done Notification | Sprint-010 track | Optional `N8N_CLAUDE_DONE_WEBHOOK_URL` webhook, fired from `scripts/review_bridge.sh check` when `claude_report.md` is READY. |
| Workflow 2 — Codex Review Done Notification | Sprint-009 | Optional `N8N_CODEX_REVIEW_DONE_WEBHOOK_URL` webhook, fired when `codex_review.md` / `codex_final_review.md` is READY. |
| Handoff Package | Sprint-010 | `handoff_package.md`, auto-generated per Manual Gate transition (Claude → Codex, Codex → Claude), embedded into notification payloads (Artifact First, no Execute Command dependency). |
| Development Principles v2.0 | Sprint-011 | `docs/development/development-principles.md`: seven Development Principles, Definition of Done, Sprint Retrospective / Product Owner Decision requirements. |
| Notification Package Specification | Sprint-012 (this Sprint) | `docs/development/notification-package-specification.md`: SSOT contract for 8 lifecycle notification events. Specification only; not yet wired into Review Bridge. |

All capabilities above belong to **AI Workspace** (Section 2.1). None of them constitute an AI Collaboration Engine (Section 2.2) or AI Decision Assistant runtime (Section 2.3).

---

## 4. Architecture Principles Carried Forward

All V1 capabilities above were built under, and continue to be governed by:

- MVP First, Architecture Second, Platform Last (`docs/development/development-principles.md` Principles 1–3).
- Architecture Before Implementation, Evidence Before Assumption (Principles 4–5).
- Manual Gate, human-in-the-loop (`docs/development/consensus-workflow.md`).
- Artifact First: every notification/handoff mechanism (Sprint-009, Sprint-010, Sprint-012) is built so that the repo artifact is authoritative and delivery channels are replaceable, best-effort, non-blocking side effects.

---

## 5. Boundaries Explicitly Not Crossed in V1

Across Sprint-002 through Sprint-012, the workspace has deliberately not introduced:

- A Database
- A Queue
- A Runtime Engine / AI Runner
- An AI Auto Loop (Auto Claude Loop, Auto Codex Loop)
- Automatic Consensus, Commit, or Push
- A Workflow Engine (in the AI Decision Assistant V3 product sense — distinct from the `scripts/review_bridge.sh` development tool)
- An AI Collaboration Engine (Section 2.2) or any AI Decision Assistant runtime (Section 2.3)

These remain explicitly out of scope for V1 and require an explicit, evidence-based Product Owner decision to introduce (Development Principle 3).

---

## 6. Sprint-012 as the V1 Final Sprint

Sprint-012 is designated the final Sprint of AI Workspace V1. Its deliverables (this document, `docs/development/operational-model.md`, `docs/development/notification-package-specification.md`, and `reviews/sprint-012/round-001/architecture.md`) complete the V1 governance and specification baseline.

After Sprint-012, the workspace operates under Maintenance Mode as defined in `docs/development/operational-model.md`.

---

## 7. Compatibility

This document does not modify any code, any existing Sprint's artifacts, `scripts/review_bridge.sh`, `docs/development/consensus-workflow.md`, or `docs/development/development-principles.md`. It is a read-only consolidation for onboarding and reference purposes.
