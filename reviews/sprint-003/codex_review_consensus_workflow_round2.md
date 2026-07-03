# Codex Review - Consensus Workflow Round 2

## Summary
FAIL

`docs/development/consensus-workflow.md` now exists and covers the main Manual Gate intent, Review Bridge role, Consensus Stop Rule, and Commit Gate requirement.

However, it is not yet sufficient to define a unique AI collaboration workflow because several core parts remain ambiguous:

- The workflow does not explicitly say `Architecture -> Claude -> Codex -> Consensus -> final_consensus.md -> Product Owner Gate -> Commit`.
- Claude and Codex responsibilities are described as interchangeable `Implementation AI` / `Reviewer AI`, which conflicts with the requested unique Claude-to-Codex flow.
- Required artifact names use alternatives such as `implementation_report.md or claude_report.md`, which weakens the single source of truth.
- Required artifact path says `reviews/<sprint-id>/`, but the Review Bridge flow uses per-round folders such as `reviews/<sprint-id>/<round-id>/`.

## Must Fix

- Replace the generic workflow with the explicit approved flow:
  `Architecture -> Claude -> Codex -> Consensus -> final_consensus.md -> Product Owner Gate -> Commit`.
- Define Claude Code as the implementation role and Codex as the review role for this workflow, unless Product Owner explicitly approves a role swap.
- Define the exact Review Bridge artifact paths:
  - `reviews/<sprint-id>/<round-id>/claude_report.md`
  - `reviews/<sprint-id>/<round-id>/codex_prompt.md`
  - `reviews/<sprint-id>/<round-id>/codex_review.md`
  - `reviews/<sprint-id>/<round-id>/consensus_report.md`
  - `reviews/<sprint-id>/final_consensus.md`
- Remove `or` alternatives from required artifact names, or clearly mark aliases as legacy compatibility only.
- Clarify that `final_consensus.md` must not be generated, accepted, or used for Commit Gate unless the latest `consensus_report.md` is PASS.

## Should Fix

- Add a short "Single Source of Truth" section stating that this document defines the unique AI collaboration workflow for Sprint-003 onward.
- Clarify how the workflow relates to `development-workflow.md`, `review-checklist.md`, and `sprint-checklist.md`.
- Add the exact PASS token expected by automation. The document currently says `Consensus: PASS` and `Consensus Stop Rule: PASS`; if the Review Bridge uses `Gate Status: PASS`, the document should align with that.
- Add explicit failure routing:
  - Codex FAIL -> Claude fix round.
  - Consensus FAIL -> next round or Product Owner decision.
  - Product Owner not approved -> no commit.

## Nit

- The phrase "Usually Claude Code or Codex" is too soft for a process-defining document.
- `Implementation Reply` should be named consistently with the artifact, for example `Claude Reply` or `claude_reply.md`.
- `Final Consensus` should consistently be written as `final_consensus.md` when referring to the commit gate artifact.

## Questions

- Should Codex ever be allowed to act as Implementation AI in this workflow, or is Codex review-only for Sprint-003?
- Is `implementation_reply.md` required in every round, or only when Codex has Must Fix items?
- Should `final_consensus.md` be generated only by Review Bridge, or can Product Owner manually create it?

## Consensus Stop Rule Review

FAIL

The document defines useful stop conditions:

- No unresolved Architecture Conflict.
- No unresolved Must Fix.
- Acceptance Criteria are satisfied.
- No scope expansion occurred.
- Open Questions are zero or accepted by Product Owner.
- Product Owner agrees to close the Sprint.

The missing part is automation/gate precision. It should explicitly state that if any stop condition fails:

- Review Bridge must not produce a valid `final_consensus.md`.
- Product Owner Gate must not proceed.
- Commit Gate must not proceed.
- The next step must be Claude fix, another review round, or explicit Product Owner decision.

## Commit Gate Review

FAIL

The document correctly states:

- `final_consensus.md` is required.
- `final_consensus.md` must say PASS.
- Product Owner approval is required.
- No final consensus means no commit.

But it does not yet define a unique artifact path and PASS format that matches the Review Bridge round structure. It should explicitly require:

- Latest round `consensus_report.md` is PASS.
- Sprint-level `reviews/<sprint-id>/final_consensus.md` exists.
- `final_consensus.md` was generated after the latest PASS consensus.
- Product Owner approves commit after reviewing `final_consensus.md`.

## Final Recommendation
FAIL
