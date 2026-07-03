# Codex Review - Sprint-005 Implementation

## Summary

Sprint-005 improves `check` output clarity, placeholder detection, consensus diagnostics, and adds a regression test suite for `scripts/review_bridge.sh`, without adding CLI commands, changing the consensus algorithm, changing deterministic marker rules, or introducing Auto Loop / Auto Commit.

Independent verification (re-reading `scripts/review_bridge.sh`, `scripts/test_review_bridge.sh`, diffing against the committed baseline, and running the regression suite plus manual probes) confirms the implementation meets the Sprint-005 Definition of Done. One real defect was found and fixed during this same round (see Must Fix, resolved) and one documentation/implementation ambiguity is logged as Should Fix for Product Owner clarification. Neither blocks Gate PASS.

## Review Scope

Reviewed artifacts and implementation evidence:

- `scripts/review_bridge.sh` (full read, diffed line-by-line against `git show HEAD:scripts/review_bridge.sh`)
- `scripts/test_review_bridge.sh` (full read, executed)
- `docs/development/consensus-workflow.md`
- `reviews/sprint-005/round-001/architecture.md`
- `reviews/sprint-005/round-001/claude_report.md`
- Manual probes beyond the existing test suite (see Test Validation)
- Real historical data: `reviews/sprint-004/round-001/` via `check` (read-only)

## Gate Status: PASS

## Architecture Compliance

PASS

Verified against `reviews/sprint-005/round-001/architecture.md` and the Architecture Constraints:

- **No new CLI commands.** Dispatcher `case` block is unchanged: `init`, `skeleton`, `check`, `validate-final-consensus`, `consensus`, `finalize`. Diff confirms only the `*)` fallback line (error message) changed.
- **Consensus Algorithm unchanged.** `diff` against the pre-Sprint-005 committed version shows the eight marker checks (`Must Fix`, `Architecture Conflict`, `Final Recommendation` ×3, `Must Fix Addressed`, `Architecture Conflict Addressed`, `Scope Expansion`) use byte-identical comparison logic (`!= "None"`, `!= "PASS"`, `!= "Yes"`, `!= "No"`). Only the fail-reason message text changed (`<not found>` fallback instead of a raw empty value).
- **Deterministic marker rules unchanged.** `parse_marker()` is byte-identical to the committed baseline (`diff` shows zero lines changed).
- **No Auto Loop / Auto Commit.** Grep for `git commit`, `git push`, `curl`, `wget`, unbounded loops, and AI-provider calls across both scripts returns no matches.
- **Workflow unchanged.** `init → skeleton → (fill artifacts) → check → consensus → finalize → validate-final-consensus` order and file names are untouched.
- **Path-traversal / input validation unchanged.** `validate_id()` and `validate_round()` are byte-identical to the committed baseline.

One item flagged for Product Owner attention — see Should Fix below (placeholder-detection scope vs. `consensus-workflow.md`'s Fill Artifacts Step).

## Security Review

PASS

- `sprint_id` is whitelisted to `^[a-z0-9][a-z0-9-]*[a-z0-9]$` (or single char) plus an explicit reject on `..`, `/`, and space, before being interpolated into `sed -i` and file paths — no injection or traversal surface. Unchanged from baseline.
- `round` is validated as a positive integer and re-emitted via `printf '%03d'` — no injection surface. Unchanged from baseline.
- **New operator-safety fix in this round, verified:** `REVIEWS_DIR` now honors `REVIEWS_OVERRIDE` (`REVIEWS_DIR="${REVIEWS_OVERRIDE:-$REPO_ROOT/reviews}"`). Before this fix, `scripts/test_review_bridge.sh` exported `REVIEWS_OVERRIDE` but the main script silently ignored it, so every regression-test run wrote `test-init/`, `test-check/`, `test-doc/`, `test-pass/`, `test-placeholder/`, `test-pl-consensus/`, `test-ready/`, and `sprint-004-e2e/` directly into the real, git-tracked `reviews/` directory. Confirmed fixed: a full test run now leaves `git status --porcelain reviews/` showing only the pre-existing Sprint-004 modifications, no new untracked directories.
- No new external command execution, network calls, or eval-style constructs introduced.

## Test Validation

PASS

`bash scripts/test_review_bridge.sh` → **50 passed, 0 failed**, exit code 0 (independently re-run, not just taken from `claude_report.md`).

Coverage confirmed adequate for the Must Have items:

- `check`: missing / placeholder / ready classification and exit codes (Tests 6–8).
- Placeholder detection: `is_placeholder()` correctly flags skeleton-generated files and is exercised in both `check` and `consensus` paths (Tests 7, 9).
- Consensus diagnostics: placeholder → `Gate Status: FAIL` with a reason, not a crash (Test 9); all-markers → `Gate Status: PASS` (Test 10).
- Path traversal rejection (Test 14), dry-run no-write guarantee (Test 15), and a full Sprint-004-shaped E2E flow (check → consensus → finalize → validate, all PASS).

Additional independent verification performed beyond the existing suite:

- Re-ran the full suite twice to confirm no flakiness and no residual pollution of `reviews/`.
- Ran `check` directly against the real, committed `reviews/sprint-004/round-001/` (read-only) — all 6 artifacts report `READY`, overall `PASS`. Confirms Sprint-004 compatibility on real data, not only the synthetic E2E fixture.
- Manually reproduced the pre-fix crash by reverting the fix locally and confirming `bash: unbound variable` on `consensus` when a placeholder is present — confirms the Must Fix below was real and the fix resolves it.

## Architecture Conflict

Architecture Conflict: None

The Should Fix item below (`codex_prompt.md` placeholder-detection scope) is a documentation/implementation ambiguity, not a conflict with the approved Sprint-005 `architecture.md`.

## Must Fix

Must Fix: None

The following was found during this review's verification pass and was **already fixed within this round** (confirmed by re-running the suite and by manual reproduction of the original failure):

- `cmd_consensus` referenced an undeclared array `${#placeholder[@]}` (singular) instead of the correctly-scoped `placeholders` (plural) array used later in the same function. Under `set -u` (bash 5.2), this crashed `consensus` with "unbound variable" whenever a placeholder artifact was present — instead of producing the required `Gate Status: FAIL` diagnostic. This directly contradicted Sprint-005 Must Have #3. Fix (already applied): removed the dead/incorrect reference; the existing `placeholders` array (used later in the function) is the single source of truth.

Since this is already resolved and independently verified in this same round, it is not counted as an open Must Fix against the Gate.

## Should Fix

1. **Placeholder-detection scope for `codex_prompt.md` is stricter than `docs/development/consensus-workflow.md`'s Fill Artifacts Step literally enumerates.** `consensus-workflow.md` explicitly lists only `architecture.md`, `claude_report.md`, `codex_review.md`, `claude_reply.md`, `codex_final_review.md` as files that "must contain actual content before `consensus` runs," and separately notes `codex_prompt.md` "must not be treated as a replacement for actual Claude or Codex review results" — implying it is not gated the same way. The current implementation's placeholder-detection loop in both `check` and `consensus` iterates over the full `required` array, which includes `codex_prompt.md`. Verified by direct probe: an otherwise fully-ready round (all 5 marker-bearing files real and PASS-worthy) still produces `check` → `WARNING`/`PLACEHOLDER` and `consensus` → `Gate Status: FAIL` solely because `codex_prompt.md` was left as the `skeleton`-generated default.
   - In practice this is unlikely to block real usage, since an operator would always replace `codex_prompt.md` with an actual prompt before sending it to Codex, and Sprint-005's own DoD line ("Placeholder cannot be mistaken as ready for consensus") does not itself exempt any file. But the two governing documents are not literally aligned, and `consensus-workflow.md` states it is "the single source of truth for AI collaboration gates."
   - Recommendation: Product Owner should pick one of (a) update `consensus-workflow.md` to explicitly state that no round file may retain the literal `skeleton` marker before `consensus`, including `codex_prompt.md`, or (b) exclude `codex_prompt.md` from the placeholder-detection loop to match the current literal wording of the Fill Artifacts Step. Not a blocker for this round — flagged as a conflict per AGENTS.md §17, not silently resolved by either agent.

## Nit

- `is_placeholder()` matches an exact literal line `^TEMPLATE ONLY$` via `grep`. A file containing that exact line for an unrelated reason (e.g., quoting the marker convention in documentation-style content) would be misclassified as a placeholder, and CRLF line endings would produce a false negative (placeholder misread as ready). Low risk given this is a bash/Linux-oriented tool and matches the pre-existing marker convention from `skeleton`; not worth added complexity for an MVP, but worth a one-line note if `check`/`consensus` are ever used outside a controlled Linux/macOS shell environment.
- No regression test currently exercises the `codex_prompt.md`-left-as-placeholder scenario described in Should Fix #1; once Product Owner decides the intended behavior, a test should be added either way (currently `codex_prompt.md` is always overwritten with real content in Tests 9/10 and the E2E fixture, so this path is untested).

## Known Limitation

- The script does not call AI tools or generate review content; review artifacts must still be filled in manually before `consensus`. (Unchanged from Sprint-004, out of scope for Sprint-005.)
- Regression tests are shell/`bash`-based assertions, consistent with the project's existing tooling; no external test framework introduced.

## Final Recommendation

Final Recommendation: PASS
