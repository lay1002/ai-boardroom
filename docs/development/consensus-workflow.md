# Consensus Workflow

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
