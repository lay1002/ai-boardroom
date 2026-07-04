# Development Principles v2.0

> AI Workspace Development Constitution

Version: 2.0

---

## 0. Status and Authority

This document is the **AI Workspace Development Constitution**.

It is the single source of truth for **Development Principles v2.0**.

It has higher authority than:

- `docs/development/development-workflow.md`
- `docs/development/consensus-workflow.md`
- Individual Sprint Architecture documents
- Individual review artifacts
- Chat history

Other workflow documents may reference these principles, but must not duplicate, redefine, or partially copy them.

Future Sprint Architecture documents MUST reference this document instead of re-listing the full principles.

This prevents drift between process documents and ensures every AI agent follows the same governance source.

---

## 1. Document Hierarchy

The official reading and authority hierarchy for every AI session is:

```text
PROJECT_BOOTSTRAP.md
↓
docs/development/development-principles.md
↓
docs/development/development-workflow.md
↓
docs/development/consensus-workflow.md
↓
Current Sprint Architecture
```

- `PROJECT_BOOTSTRAP.md` is the entry document for every AI session. It instructs every session to read the documents above, in order, before starting Architecture, Implementation, Review, or Git work.
- This document (`development-principles.md`) defines Development Principles v2.0, the Definition of Done, Product Owner Decision requirements, and Sprint Retrospective requirements.
- `development-workflow.md` and `consensus-workflow.md` describe operational steps and gate mechanics. They must reference this document and must not duplicate or override it.

---

## 2. Development Principles v2.0

Development Principles v2.0 contains **seven principles**. No eighth principle exists.

Each principle uses the following field structure so it is operational, not merely aspirational:

- **Rule**
- **Responsibility**
- **Scope**
- **Trigger / When**
- **Required Evidence**
- **Expected Outcome**

### Principle 1: MVP First

- **Rule**: The workspace prioritizes the smallest usable, verifiable outcome before platform abstractions.
- **Responsibility**: All AI agents and Product Owner.
- **Scope**: Every Sprint's scope decision.
- **Trigger / When**: Whenever a new feature or capability is proposed.
- **Required Evidence**: Sprint Architecture explicitly defines a minimal, deliverable scope.
- **Expected Outcome**: Every Sprint produces a verifiable, deliverable outcome without premature abstraction.

### Principle 2: Architecture Second

- **Rule**: Architecture must support MVP delivery and must not delay delivery through premature abstraction.
- **Responsibility**: Chief Product Architect (ChatGPT).
- **Scope**: Architecture design for each Sprint.
- **Trigger / When**: Whenever Architecture is proposed for a Sprint.
- **Required Evidence**: The Architecture document explicitly states In Scope / Out of Scope and does not introduce unproven abstractions.
- **Expected Outcome**: Architecture accelerates delivery instead of blocking it.

### Principle 3: Platform Last

- **Rule**: Platform, framework, and shared abstractions are introduced only after repeated real needs are proven.
- **Responsibility**: Chief Product Architect (ChatGPT) and Product Owner.
- **Scope**: Introduction of any new Framework, Platform, Engine, or shared abstraction.
- **Trigger / When**: Whenever a new abstraction is proposed.
- **Required Evidence**: At least one of — two or more features need the same capability, duplicate implementation already exists, or the abstraction clearly reduces maintenance cost without delaying MVP.
- **Expected Outcome**: No speculative Platform or Framework is introduced ahead of proven need.

### Principle 4: Architecture Before Implementation

- **Rule**: Implementation must follow approved Architecture. AI agents must not implement runtime changes before Architecture is approved.
- **Responsibility**: Claude Code.
- **Scope**: All Implementation Sprints.
- **Trigger / When**: Before any Claude Code implementation begins.
- **Required Evidence**: `reviews/<sprint-id>/round-<nnn>/architecture.md` (or `reviewed_document.md` for Documentation Sprints) exists and is approved before `claude_report.md` is produced.
- **Expected Outcome**: No implementation occurs without a corresponding approved Architecture record.

### Principle 5: Evidence Before Assumption

- **Rule**: Decisions, reviews, and implementation claims must be grounded in repository artifacts, test output, or explicit Product Owner decisions.
- **Responsibility**: All AI agents.
- **Scope**: Every claim of completion, correctness, or review result.
- **Trigger / When**: Whenever an AI agent reports a result (implementation complete, review PASS, test PASS).
- **Required Evidence**: Test output, file diffs, or explicit Product Owner statements referenced in the corresponding report.
- **Expected Outcome**: No claim is accepted without evidence traceable in the repository or an explicit Product Owner record.

### Principle 6: Sprint Retrospective is Mandatory

- **Rule**: Every Sprint MUST complete a standardized Sprint Retrospective. The retrospective is part of the Definition of Done. It MUST include a Product Owner Decision section documenting governance decisions for future traceability.
- **Responsibility**: Claude Code (drafts the retrospective), Product Owner (records the decision).
- **Scope**: Every Sprint, regardless of Sprint Type.
- **Trigger / When**: Before a Sprint may be marked DONE.
- **Required Evidence**: A Sprint Retrospective following the Rule 6 Mandatory Template (Section 3), including a completed Product Owner Decision section.
- **Expected Outcome**: Every Sprint leaves a traceable governance record independent of chat history.

### Principle 7: Process Improvement Never Goes Backwards

- **Rule**: Once a process improvement is accepted into the Development Constitution, future Sprints must preserve or strengthen it unless Product Owner explicitly creates a new Sprint to change the governance rule.
- **Responsibility**: All AI agents and Product Owner.
- **Scope**: All governance and process documents.
- **Trigger / When**: Whenever a future Sprint touches governance documents.
- **Required Evidence**: A new Sprint Architecture explicitly documents the intent to change a prior governance rule, approved by Product Owner.
- **Expected Outcome**: Governance quality is monotonically non-decreasing across Sprints.

---

## 3. Rule 6 Mandatory Template

Sprint Retrospective MUST use at least the following structure:

```markdown
# Sprint Retrospective

## 1. Objective

## 2. Root Cause

## 3. Lessons Learned

## 4. Process Improvement

## 5. Backlog

## 6. Product Owner Decision

### 6.1 Accepted

### 6.2 Rejected

### 6.3 Deferred

### 6.4 New Backlog

### 6.5 Strategic Decisions

### 6.6 Rationale

### 6.7 Decision Principles
```

---

## 4. Product Owner Decision Requirements

Product Owner Decision is **not** a new eighth principle. It is part of **Principle 6 (Sprint Retrospective is Mandatory)**.

Each Product Owner Decision section MUST include the following decision categories when applicable:

- Accepted
- Rejected
- Deferred
- New Backlog
- Strategic Decisions
- Rationale
- Decision Principles

### 4.1 Decision Principles

Decision Principles MUST reference the applicable Development Principles defined in Section 2 of this document.

Each Product Owner decision MUST explicitly identify which Development Principles were applied, and provide a brief rationale explaining how those principles influenced the decision.

The Sprint Retrospective template MUST NOT hardcode a fixed list of principle names. This prevents template churn when Development Principles are expanded or revised in a future Sprint (see Principle 7).

---

## 5. Definition of Done

Definition of Done is the common completion standard for all AI Workspace Sprints.

A Sprint is considered **DONE** only when ALL of the following are complete:

- Architecture Approved
- Architecture Verification PASS
- Implementation Complete
- Implementation Review PASS
- End-to-End Validation PASS
- Git Review PASS
- Sprint Retrospective Completed
- Product Owner Decision Recorded
- Product Owner Final Approval

This Definition of Done applies to all Sprints. Individual Sprints must not lower or bypass this standard.

---

## 6. Partial Completion is NOT Done

Partial completion is **NOT** considered Done.

Skipping any mandatory governance activity, including Sprint Retrospective or Product Owner Decision, invalidates Sprint completion.

The following are explicitly **not** equivalent to Sprint completion:

```text
Code Complete
!= Sprint Complete

Commit Complete
!= Sprint Complete

Push Complete
!= Sprint Complete
```

Only a Sprint that satisfies the full Definition of Done (Section 5) may be marked DONE.

---

## 7. Relationship to Other Documents

`docs/development/development-workflow.md` and `docs/development/consensus-workflow.md` describe operational steps and Review Bridge gate mechanics.

They MUST reference this document for Development Principles and the Definition of Done, and MUST NOT duplicate or redefine them.

Individual Sprint Architecture documents MUST reference this document instead of re-listing the full principles.
