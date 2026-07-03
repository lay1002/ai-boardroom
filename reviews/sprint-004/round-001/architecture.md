# Sprint-004 Architecture - Review Bridge Automation MVP

## Sprint

Sprint-004

## Scope

Implement a minimal Review Bridge automation script for the development workflow.

The MVP scope is limited to deterministic file and marker gates for review artifacts. It is a development tool only and is not part of the V3 runtime.

## Goals

- Initialize Sprint review metadata.
- Create round input artifact skeletons by Sprint Type.
- Check required input artifact existence by Sprint Type.
- Generate consensus_report.md from existing review artifacts and deterministic markers.
- Generate final_consensus.md only after consensus_report.md has Gate Status: PASS.
- Validate final_consensus.md placement before Commit Gate.

## Supported Commands

- init
- skeleton
- check
- consensus
- finalize
- validate-final-consensus

## Sprint Types

Supported Sprint Types:

- implementation
- documentation

SPRINT_TYPE must be deterministic metadata and must be validated with a whitelist.

## Manual Gate Requirements

Review Bridge must not:

- Call Claude or Codex automatically.
- Start another review round automatically.
- Modify product code.
- Auto-commit.
- Bypass Product Owner Gate.

## Artifact Rules

Implementation Sprint input artifacts:

- architecture.md
- claude_report.md
- codex_prompt.md
- codex_review.md
- claude_reply.md
- codex_final_review.md

Generated gate artifacts:

- consensus_report.md
- final_consensus.md

skeleton must create input artifact placeholders only. It must not create consensus_report.md or final_consensus.md.

## Consensus Stop Rule

Consensus must be based only on deterministic markers in existing artifacts.

Required PASS conditions:

- codex_review Must Fix: None
- codex_review Architecture Conflict: None
- codex_review Final Recommendation: PASS
- claude_reply Must Fix Addressed: Yes
- claude_reply Architecture Conflict Addressed: Yes
- claude_reply Final Recommendation: PASS
- codex_final_review Final Recommendation: PASS
- claude_report Scope Expansion: No

If any marker is missing or has a failing value, consensus_report.md must produce Gate Status: FAIL.

## Commit Gate

final_consensus.md may be generated only after consensus_report.md says Gate Status: PASS.

validate-final-consensus must be run after finalize and before Product Owner Commit Gate.

No final_consensus.md, no commit.
No Product Owner approval, no commit.
