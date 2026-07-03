# Claude Report - Sprint-005 Implementation

## Summary

Improved usability and operator safety of `scripts/review_bridge.sh` (Review Bridge Automation MVP). No new commands were added, and the consensus algorithm / deterministic marker rules are unchanged.

Most of the Must Have and Should Have scope (improved `check` output, placeholder detection via a `TEMPLATE ONLY` marker, improved CLI help/usage/error messages, and a new regression test suite) already existed in the working tree as uncommitted changes at the start of this Sprint. My implementation work consisted of (a) verifying that pre-existing uncommitted work actually satisfies the Sprint-005 Definition of Done, and (b) fixing two root-cause defects discovered during verification that were silently breaking `consensus` and polluting the repository's real `reviews/` directory.

## Modified Files

- `scripts/review_bridge.sh`

## New Files

- `scripts/test_review_bridge.sh` (regression test suite, pre-existing uncommitted, verified and now passing)
- `reviews/sprint-005/round-001/architecture.md` (this round's architecture record)
- `reviews/sprint-005/round-001/claude_report.md` (this file)

## Root Cause Fixes (this Sprint)

### 1. `consensus` crashed with "unbound variable" whenever placeholders were present

`cmd_consensus` referenced `${#placeholder[@]}` (singular, never declared in that function's scope) while the real placeholder-detection array was named `placeholders` (plural). Under `set -u` (bash 5.2), this crashed the `consensus` command outright instead of producing a diagnostic `Gate Status: FAIL`. This is the exact failure mode Sprint-005 Must Have #3 ("Improve consensus diagnostics") targets — a placeholder artifact must produce a clear FAIL, not a crash.

Fix: removed the dead/incorrect reference; the existing, correctly-scoped `placeholders` array (used later in the function) already performs this check and is now the single source of truth.

### 2. Regression tests were not isolated — they wrote into the real `reviews/` directory

`scripts/test_review_bridge.sh` exports `REVIEWS_OVERRIDE` to sandbox test runs into a temp directory, but `review_bridge.sh` never read that variable — `REVIEWS_DIR` was hardcoded to `$REPO_ROOT/reviews`. Every test run was silently writing `test-init/`, `test-check/`, `test-doc/`, `test-pass/`, `test-placeholder/`, `test-pl-consensus/`, `test-ready/`, and `sprint-004-e2e/` directly into the project's real `reviews/` directory. This is an operator-safety defect directly in scope for this Sprint's title ("... & Operator Safety").

Fix: `REVIEWS_DIR="${REVIEWS_OVERRIDE:-$REPO_ROOT/reviews}"`. When `REVIEWS_OVERRIDE` is unset (normal operator use), behavior is byte-for-byte identical to before. Also removed the stray test directories that had already leaked into `reviews/` from prior runs (all were untracked, confirmed via `git ls-files` before deletion).

### 3. Minor duplication removed

`cmd_consensus` recomputed an `all_input` array identical to the `required` array already computed earlier in the same function. Replaced the duplicate `case` block with a reference to `required`.

## Improvements Verified as Present (pre-existing uncommitted work, kept as-is)

- `check` now reports **Missing / Placeholder / Ready** per file, with an overall `PASS` / `WARNING` (placeholder) / `FAIL` (missing) summary.
- `is_placeholder()` detects skeleton-generated files via a `^TEMPLATE ONLY$` marker; placeholder artifacts fail `consensus` (`Gate Status: FAIL`) and cannot be mistaken for ready content.
- `usage()` documents every command's purpose and the placeholder rule.
- Unknown-command errors now point the operator back to `usage`.
- `consensus` now also reports fail reasons per artifact type in `consensus_report.md`.

## Improvements Added (this session, on top of the above)

- `consensus` now also prints `Fail Reasons:` to stdout (not just inside `consensus_report.md`), so a FAIL is diagnosable without opening a file.
- `init` now prints `Created:` / `Written:` confirmation lines instead of completing silently, so an operator can confirm what was created.

## Out of Scope (untouched, per Architecture Constraints)

- No new CLI commands.
- Consensus Algorithm (PASS/FAIL evaluation rules) unchanged.
- Deterministic marker rules (`Must Fix`, `Architecture Conflict`, `Final Recommendation`, `Must Fix Addressed`, `Scope Expansion`, etc.) unchanged.
- No Auto Loop, no Auto Commit.
- Review Bridge workflow order (init → skeleton → fill → check → consensus → finalize → validate) unchanged.
- Pre-existing uncommitted edits to `reviews/sprint-004/round-001/{architecture,claude_report,codex_review}.md` (a "Reconstruction Notice" section) predate this session and are unrelated to Sprint-005 scope — left untouched.
- Untracked root-level files (`architecture_review.md`, `template_engine_design.md`, etc.) belong to an unrelated Template Engine MVP track — left untouched.

## Test Results

`bash scripts/test_review_bridge.sh` — **50 passed, 0 failed**, exit code 0.

Covers: init (incl. round creation, duplicate-round rejection), skeleton (implementation + documentation types, gate artifacts not created), check (missing / placeholder / ready states and exit codes), consensus (placeholder → FAIL, all markers → PASS), finalize (gate enforcement, marker summary, Sprint Type recorded), validate-final-consensus (correct placement), path traversal rejection (4 cases), dry-run (no writes), and a full Sprint-004-shaped E2E flow (check → consensus → finalize → validate, all PASS).

Confirmed after the fix: no test run writes outside the temp `REVIEWS_OVERRIDE` directory; `git status --porcelain reviews/` shows no new untracked directories after a full test run.

## Known Limitations

- The script does not call AI tools or generate review content; review artifacts must still be filled in manually before `consensus`.
- `is_placeholder()` matches on an exact literal line `TEMPLATE ONLY`; a manually-authored file that happens to contain that exact line would be misclassified as a placeholder. This matches the marker convention already established by `skeleton` and is unchanged from the pre-existing implementation.
- Regression tests are shell-based (`bash` assertions), consistent with the existing project's tooling; no external test framework was introduced.

## Scope Control

Scope Expansion: No

## Recommendation

Ready for Codex review and Review Bridge consensus once `codex_prompt.md`, `codex_review.md`, `claude_reply.md`, and `codex_final_review.md` are filled in for this round.
