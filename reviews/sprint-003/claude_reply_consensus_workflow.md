# Claude Reply - Consensus Workflow Fix

## Summary

Updated `docs/development/consensus-workflow.md` to define one fixed AI collaboration workflow with non-interchangeable Claude Code and Codex roles.

## Files Changed

- `docs/development/consensus-workflow.md`
- `reviews/sprint-003/claude_reply_consensus_workflow.md`

## Codex Issues Addressed

- Replaced generic Implementation AI / Reviewer AI wording with fixed Claude Code Implementation and Codex Review roles.
- Defined the unique workflow from ChatGPT Architecture through Commit.
- Fixed Review Bridge artifact paths to `reviews/<sprint-id>/round-001/`.
- Removed `or` artifact naming from the canonical workflow.
- Defined additional rounds as `round-002`, `round-003`, and onward.
- Defined `final_consensus.md` as valid only in the final round directory.
- Preserved Manual Gate and Consensus Stop Rule.

## Tests / Validation

Documentation-only change. Validated by rereading the updated workflow for required role, artifact, gate, and stop-rule language.

## Recommendation

Ready for Codex Round 3 Review.
