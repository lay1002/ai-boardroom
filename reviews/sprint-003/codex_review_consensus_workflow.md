# Codex Review - Consensus Workflow

## Summary
FAIL

Target document `docs/development/consensus-workflow.md` does not exist in the current workspace. Because the document is missing, it cannot define a unique AI collaboration workflow.

## Must Fix

- Create `docs/development/consensus-workflow.md`.
- The document must explicitly define the full flow:
  `Architecture -> Claude -> Codex -> Consensus -> final_consensus.md -> Product Owner Gate -> Commit`.
- The document must define Claude and Codex responsibility boundaries.
- The document must define Review Bridge as a gate coordination artifact generator, not as V3 Runtime.
- The document must define the Consensus Stop Rule.
- The document must state that `final_consensus.md` is required before Commit Gate.
- The document must state that no consensus means no next step.
- The document must explicitly preserve Manual Gate and reject Auto Loop behavior.

## Should Fix

- Add a single source-of-truth section that says this document supersedes older development-flow descriptions when defining the Claude/Codex/Consensus handoff.
- Add required file paths and artifact ownership:
  - `claude_report.md`
  - `codex_prompt.md`
  - `codex_review.md`
  - `consensus_report.md`
  - `final_consensus.md`
- Add PASS / FAIL criteria for `consensus_report.md`.
- Add a clear rule that Commit may proceed only after Product Owner approval, even when `final_consensus.md` is PASS.

## Nit

- None. The target document is missing, so style-level review is not applicable.

## Questions

- Should `docs/development/consensus-workflow.md` become the only authoritative workflow document for Sprint-003 onward?
- Should existing files such as `development-workflow.md`, `review-checklist.md`, and `sprint-checklist.md` reference this new consensus workflow to avoid conflicting instructions?

## Consensus Stop Rule Review

FAIL

The target document is missing, so the Consensus Stop Rule is not defined there.

Minimum required rule:

- If Codex Review is not PASS, Review Bridge must stop.
- If `consensus_report.md` does not contain `Gate Status: PASS`, Review Bridge must not generate or treat `final_consensus.md` as valid.
- If consensus is not reached, Product Owner Gate and Commit Gate must not proceed.
- The next action must be human review or Claude fix, not automatic continuation.

## Commit Gate Review

FAIL

The target document is missing, so it does not establish `final_consensus.md` as the required Commit Gate artifact.

Minimum required rule:

- Commit Gate requires `final_consensus.md`.
- `final_consensus.md` must be generated only after PASS consensus.
- Product Owner approval is still required after `final_consensus.md`.
- No AI agent may auto-commit.

## Final Recommendation
FAIL
