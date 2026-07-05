# AI Workspace Operational Model

Version: 1.0 (Sprint-012)

---

## 0. Authority

This document operates under `docs/development/development-principles.md` (the AI Workspace Development Constitution) and `docs/development/consensus-workflow.md`. It does not redefine either. It defines how the workspace operates on a day-to-day basis after AI Workspace V1 is established (Sprint-012), including the transition into Maintenance Mode.

This document governs AI Workspace V1 only. It does not define AI Collaboration Engine or AI Decision Assistant runtime behavior (see `docs/architecture/ai-workspace-v1-architecture-baseline.md` Section 2, Product Boundary).

---

## 1. Purpose

Prior Sprints (Sprint-002 through Sprint-011) established the workspace's core capabilities incrementally: Template Engine, Prompt Generator, Review Bridge automation, Telegram notifications (Workflow 1/2), Sprint-010 Handoff Package, and Sprint-011 Development Principles v2.0.

Sprint-012 declares these capabilities, together with the Notification Package specification, as **AI Workspace V1** — the first baseline considered complete enough to operate against without further foundational (governance/process) Sprints.

This document defines what changes, and what does not change, once V1 is established.

---

## 2. AI Workspace V1 Baseline

AI Workspace V1 consists of the following established capabilities, each already implemented and reviewed in a prior Sprint:

- Template Engine (Sprint-002)
- Review Bridge automation (`scripts/review_bridge.sh`, `scripts/test_review_bridge.sh`) (Sprint-004, Sprint-005)
- Prompt Generator (Sprint-008)
- Workflow 1: Claude Done Notification (Sprint-010 track)
- Workflow 2: Codex Review Done Notification (Sprint-009)
- Handoff Package (Sprint-010)
- Development Principles v2.0 (Sprint-011)
- Notification Package Specification (Sprint-012, this Sprint — specification only, not yet wired into Review Bridge)

Full details of each capability live in their own Sprint's `reviews/<sprint-id>/round-001/` artifacts and referenced `docs/development/*.md` files. This document does not duplicate them; see `docs/architecture/ai-workspace-v1-architecture-baseline.md` for the consolidated baseline summary.

---

## 3. Maintenance Mode

After Sprint-012, the AI Workspace enters **Maintenance Mode**.

### 3.1 What Maintenance Mode Means

- New Sprints are expected to be small, targeted, and evidence-driven (bug fixes, small enhancements, documentation corrections) rather than establishing new governance or architecture layers.
- Development Principle 3 (Platform Last) applies with heightened scrutiny: no new Framework, Platform, Engine, or cross-cutting abstraction may be introduced without an explicit Product Owner decision citing a proven, repeated need.
- The existing Manual Gate (per `docs/development/consensus-workflow.md`) remains fully in force. Maintenance Mode does not relax any Gate, does not permit Auto Commit/Push/Loop, and does not change any role's responsibilities.

### 3.2 What Maintenance Mode Does Not Mean

- It does not mean the workspace is frozen or that no further Sprints may occur.
- It does not exempt any future Sprint from the Definition of Done (`docs/development/development-principles.md` Section 5) or from Sprint Retrospective / Product Owner Decision requirements (Section 2, Principle 6).
- It does not retroactively change or invalidate any completed Sprint (Sprint-002 through Sprint-012).

### 3.3 Exiting Maintenance Mode

If Product Owner determines that a new foundational capability is needed (e.g. a new Platform, Runtime Engine, or governance layer), that decision must be made explicitly, in a dedicated Sprint Architecture, citing which proven need justifies it (per Development Principle 3). Maintenance Mode is not a permanent state; it is the operating default until such a decision is made.

---

## 4. Role Operating Model in Maintenance Mode

Roles are unchanged from `docs/development/development-workflow.md` Section 3 and `docs/development/consensus-workflow.md` Roles section:

- **Product Owner**: Sprint scope, final decision, Product Owner Gate, commit approval.
- **ChatGPT (Chief Product Architect)**: Architecture for any new Sprint, however small.
- **Claude Code**: Implementation only, within approved Architecture.
- **Codex**: Review only.
- **Review Bridge**: Deterministic gate coordination; unchanged.

Maintenance Mode does not introduce, remove, or merge any of these roles.

---

## 5. Relationship to Notification Package Specification

`docs/development/notification-package-specification.md` (Sprint-012) defines the SSOT contract for future notification tooling across the 8 lifecycle events relevant to Maintenance Mode Sprints (architecture review, implementation, review, PO validation, git review, commit, push).

Wiring this specification into `scripts/review_bridge.sh` or any delivery channel is explicitly deferred to a future Implementation Sprint, to be evaluated under Development Principle 3 (Platform Last) like any other Maintenance Mode proposal.

---

## 6. Compatibility

This document does not modify:

- `scripts/review_bridge.sh` or `scripts/test_review_bridge.sh`
- `docs/development/consensus-workflow.md` gate mechanics
- `docs/development/development-principles.md` Development Principles or Definition of Done
- Any completed Sprint's artifacts (`reviews/sprint-002` through `reviews/sprint-011`)
