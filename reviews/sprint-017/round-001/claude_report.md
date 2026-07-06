# Claude Implementation Report - Sprint-017

## Summary

Sprint-017 formalizes 6 process improvements into AI Workspace's documents, code, and tests: (1) every formal Handoff Package must open with the full 10-item reading list, never a shortened one; (2) Claude/Codex reports must include a Context Completeness Check; (3) every formal Handoff Package must include a Telegram Notification block with a real, canonical `gate_id`; (4) `notify-gate` remains strictly Product-Owner-triggered, never auto-executed by Claude/Codex; (5) Manual Handoff (chat-based) is explicitly distinguished from Formal Telegram Gate Notification; (6) the Sprint Retrospective / Actual Flow Report must include a Flow Deviation Check.

The two existing, code-generated Handoff Packages (`write_handoff_package_claude_to_codex`, `write_handoff_package_codex_to_claude` in `scripts/review_bridge.sh`) were updated to actually produce this standardized content — this was the most concrete, testable place to enforce items 1 and 3, since these functions are Review Bridge's only current source of a machine-generated Handoff Package.

## Files Changed

**Modified:**

```text
scripts/review_bridge.sh                                          — full reading list + Telegram Notification block in both Handoff Package generators; explicit no-auto-invocation comment on cmd_notify_gate
scripts/test_review_bridge.sh                                      — new Test 26 (16 sub-assertions)
docs/development/consensus-workflow.md                              — new sections: Handoff Package Standard, Report Context Completeness Check, Retrospective Flow Deviation Check
docs/development/telegram-po-gate-notification-specification.md    — new sections: notify-gate Execution Policy (§18), Manual Handoff vs. Formal Telegram Gate Notification (§19)
```

**Created:**

```text
reviews/sprint-017/round-001/architecture.md
reviews/sprint-017/round-001/claude_report.md（本檔案）
```

**Not modified, with reason** (deviating from the two Allowed-candidate documentation files that were not actually touched):

- `docs/development/execution-permission-policy.md` — not modified. The notify-gate-specific policy content (item 4) fit more naturally and non-redundantly into `telegram-po-gate-notification-specification.md`, which already owns all notify-gate-related rules (Sections 1–17). Duplicating the same rule across two policy documents would create a drift risk without adding clarity.
- `docs/development/development-workflow.md` — not modified. This document's structure (ACE Lite, Chief Product Architect) did not contain the Handoff Package / Report / Retrospective conventions this Sprint touches; `docs/development/consensus-workflow.md` is the document that actually governs the Review Bridge Handoff Package and report artifacts referenced by this Sprint's requirements, so all Sprint-017 documentation changes were consolidated there instead.

**Additional file touched beyond the initial Allowed-candidate list, per the Handoff Package's own instruction** ("若 repo 中已有更精準的 handoff template / report template 檔案，請列入 Implementation Report 並依 Architecture Artifact 更新")：

- **Not modified**: `docs/development/development-principles.md`. This is explicitly the "AI Workspace Development Constitution" with higher authority than `consensus-workflow.md`, and it already contains the canonical Sprint Retrospective "Rule 6 Mandatory Template" (Section 3). Sprint-017's Flow Deviation Check requirement was intentionally documented as an **additional required section** in `consensus-workflow.md` instead (see its new "Retrospective Flow Deviation Check" section), which explicitly states the relationship to the Constitution's template and defers any change to the Constitution itself to a future, dedicated Sprint. This was a deliberate choice to avoid unilaterally editing the highest-authority governance document outside an explicitly scoped Sprint for that purpose — flagged here for Product Owner visibility rather than done silently.

## Implementation Details

1. **`_full_reading_list_zh()`** (new helper in `scripts/review_bridge.sh`) — renders the exact, standardized 10-item reading list plus the Missing Context instruction. Used by both Handoff Package generators so the text is identical everywhere, not hand-duplicated.
2. **`_telegram_notification_block()`** (new helper) — renders the 6-field Telegram Notification block for a given `gate_id`/`sprint_id`/`round`/`artifact_path`. It only renders text; it never calls `notify-gate` or sends anything.
3. `write_handoff_package_claude_to_codex()` — "## 4. Required Reading" and "## 8. Copyable Prompt" now both use the full reading list (previously a 3–5 item shortened list); new "## 9. Telegram Notification" section added, using `gate_id=claude_implementation_report_acceptance` (the canonical Gate — per `docs/development/product-owner-gate-metadata.md` — that represents Product Owner accepting `claude_report.md` and deciding whether to forward it to Codex, which is exactly what this Handoff Package is for).
4. `write_handoff_package_codex_to_claude()` — same reading-list update; new Telegram Notification section using `gate_id=codex_review_result_decision` (the canonical Gate for Product Owner's decision after reading `codex_review.md`, which is exactly what this Handoff Package hands to Claude Code for).
5. A code comment was added directly above `cmd_notify_gate()` stating the invariant that it is only ever invoked from the CLI dispatcher, confirmed by static analysis (Test 26h) that no other call site exists in the file.
6. Verified (did not need to change) that `cmd_notify_gate`'s existing parameter order is already `gate_id sprint_id round artifact_path` — matches the Handoff Package's required CLI format exactly; only the documentation (Telegram Gate spec §18) needed to state this explicitly.

## Context Completeness Check

- Full required reading list provided: PASS
- Missing context files: None
- Did missing context affect implementation or review: NO
- Notes: All 10 files in this Handoff Package's own required reading list (`PROJECT_BOOTSTRAP.md`, `AGENTS.md`, `GPT.md`, `CLAUDE.md`, `CODEX.md`, `docs/development/development-workflow.md`, `docs/development/consensus-workflow.md`, `docs/development/n8n-claude-done-notification.md`, `docs/development/n8n-codex-review-done-notification.md`, `scripts/review_bridge.sh`) were confirmed to exist before implementation began.

## Tests

```bash
bash scripts/test_review_bridge.sh
```

```text
Results: 211 passed, 0 failed
```

New Test 26 (16 sub-assertions: 26a–26o) covers all 10 Sprint-017 Test Requirements:

1. Handoff Package contains the full reading list (26a).
2. Handoff Package does not use a shortened reading list — verified positively by requiring all 10 items present, and the Missing Context instruction (26a/26b).
3. Handoff Package contains the Telegram Notification block (26c, 26g).
4. Telegram Notification block contains all 6 required fields (26d).
5. Claude report template includes Context Completeness Check — documented requirement verified (26i, 26j).
6. Codex report template includes Context Completeness Check — same documentation, same verification (26i, 26j).
7. Missing context rule is documented (26b, and the Handoff Package Standard section in `consensus-workflow.md`).
8. `notify-gate` cannot be auto-executed by Claude/Codex — static source-code proof that `cmd_notify_gate` has exactly one call site, the CLI dispatcher (26h).
9. Manual handoff is not conflated with Telegram notification completed — documentation-level verification (26k, 26l).
10. Retrospective / Actual Flow Report template includes Flow Deviation Check (26n, 26o).

Additionally, 26e verifies the `gate_id` used in a real generated Handoff Package is one of the 21 canonical gate IDs (not a placeholder), and 26m-1/26m-2 verify the notify-gate Execution Policy wording and correct CLI parameter order are documented. The full pre-existing suite (195 tests before this round, including Sprint-013/014/015/016 coverage) passes unchanged in the same run — zero regression.

## Scope Control

Implementation matches Architecture Section 2 (6 In Scope items) exactly — no more, no less. No Database, Queue, Worker, Web UI, AI Auto Loop, automatic Claude/Codex invocation, automatic Commit, or automatic Push was introduced. No API contract was changed. No new engine, provider, memory, workflow runtime, queue, dashboard, or plugin system was introduced. `scripts/review_bridge.sh`'s `notify` (Sprint-013), `notify-gate`'s delivery mechanism (Sprint-014/016), and Telegram delivery behavior are all unchanged — this Sprint only changed the *content rendered into* the two Handoff Package templates and the CLI-adjacent documentation, not how or whether anything is sent.

## Repository Hygiene Check

`git status --short` and `git diff --name-only` were reviewed before finishing. Only the 5 files listed under "Files Changed" (Modified) plus 2 new files under "Created" reflect Sprint-017 changes. No unrelated dirty/untracked file was staged, modified, moved, or deleted:

```text
AGENTS.md, CLAUDE.md, CODEX.md, GPT.md, docs/architecture.md, docs/vision.md,
docs/principles.md, docs/roadmap.md, reviews/sprint-004/round-001/*,
reviews/notification-gap-review.md, reviews/sprint-006/, reviews/sprint-007/,
reviews/sprint-009/
```

all remain in their pre-existing dirty/untracked state, untouched by this Sprint. Sprint-013/014/015/016 closed artifacts (`reviews/sprint-013/round-001/*`, `reviews/sprint-014/round-001/*`, `reviews/sprint-015/round-001/*`, `reviews/sprint-016/round-001/*`) were not modified. No `git add`, `git commit`, or `git push` was executed (`git diff --cached --name-only` is empty).

## Runtime Evidence Exclusion Check

No runtime evidence was generated in the real repository. All Test 26 handoff-package generation ran against `REVIEWS_OVERRIDE`-isolated temp directories (`$TEST_DIR`), never the real `reviews/` tree. `reviews/notification_history.jsonl` and `reviews/sprint-013/round-001/notifications/` remain in their pre-existing untracked state (byte-identical; not touched by this Sprint's work). `configs/n8n/*.json` show no diff.

## Telegram / notify-gate Safety Check

- Did Claude execute notify-gate: NO
- Did Claude trigger Telegram: NO
- Is notify-gate still Product Owner controlled: YES

## Known Limitations

1. The `gate_id` mapping chosen for each of the two code-generated Handoff Packages (`claude_implementation_report_acceptance` for Claude→Codex, `codex_review_result_decision` for Codex→Claude) is a reasonable, documented interpretation of which of the 21 canonical Gates each Handoff Package corresponds to, based on `docs/development/product-owner-gate-metadata.md`'s existing Gate descriptions — it is not itself a value explicitly dictated by the Sprint-017 Architecture (which only required "a real gate_id, not a placeholder"). Product Owner may adjust this mapping if a different Gate is intended.
2. `docs/development/development-principles.md` was deliberately left unmodified (see Files Changed); the Flow Deviation Check is currently only enforced as an *additional* documented requirement in `consensus-workflow.md`, not yet folded into the Constitution's own canonical Retrospective template text.
3. No `reviews/sprint-016/round-001/sprint_retrospective.md` (or any file matching `*retrospective*`) exists in the repository; the "Sprint-016 Retrospective 中確認的流程改善項" referenced by this Sprint's goal was taken as given directly from this Handoff Package's own Section 2 (6 In Scope items) rather than read from a separate retrospective artifact — this is recorded here for transparency, not as a Missing Context blocker, since the Handoff Package itself fully specified the required work.
4. This Handoff Package Standard and the Context Completeness Check are, going forward, authoring conventions for whoever writes a Handoff Package or a Claude/Codex report by hand (e.g. Product Owner composing a chat-based instruction, or Claude/Codex writing `claude_report.md`/`codex_review.md`); nothing in Review Bridge enforces them at the tooling level for hand-authored content — only the two script-generated Handoff Packages are enforced by code (and covered by Test 26).

## Sprint-017 Must Fix Round (Product Owner Validation Blocked)

### Product Owner Validation Blocker

Product Owner reported: "Product Owner did not receive any Telegram notification. The current flow still behaves as chat-based manual handoff, not formal Telegram Gate Notification." Product Owner Validation for Sprint-017 was BLOCKED on this basis.

### Root Cause

The original implementation's `_telegram_notification_block()` was **descriptive but not actionable**. It correctly rendered `Should notify Product Owner: YES` and a real canonical `gate_id` for both code-generated Handoff Packages (this part was never wrong), but it stopped there — it never gave Product Owner the literal `notify-gate` command to run. Since nothing in the system auto-executes `notify-gate` (by design — that boundary is intentional and correct), a Telegram Notification block that only *states intent* without providing an *executable command* results in nobody ever running it: Product Owner has no copy-pasteable action to take, so the block is functionally indistinguishable from a plain chat-based manual handoff, even though its fields said "YES." This is why the flow "still behaved as chat-based manual handoff" despite the code already producing `Should notify Product Owner: YES` — the missing piece was actionability, not the recipient/gate_id fields themselves.

A secondary, related defect was found and fixed while implementing the command: the naive rendering of `PROJECT_NAME` into the command was **unquoted**, so any real-world project name containing a space (e.g. "AI Workspace") would have silently broken the copy-pasted command even after this fix, by splitting it into two shell words. This is now fixed and covered by a regression test (26e-mf4) that deliberately uses a spaced `PROJECT_NAME`.

A tertiary defect: the round value would have rendered as the display form `round-001` in a naive fix, which `notify-gate`'s `validate_round` rejects (it requires a bare integer) — the fix derives the bare round from the display form instead of duplicating it, so the two can never drift, and this is covered by 26e-mf3d/26e-mf3e.

### Must Fix Resolution

1. **`_telegram_notification_block()` never defaults to NO/N/A** for a formal PO Gate handoff — reconfirmed unchanged behavior (it always renders `YES` + the real `gate_id` passed to it); a regression test (26e-mf1/26e-mf2) now asserts this explicitly rather than relying on manual inspection.
2. The block now includes two new required lines:
   - **`notify-gate command`**: the exact, copy-pasteable command — `PROJECT_ID="..." PROJECT_NAME="..." ./scripts/review_bridge.sh notify-gate <gate_id> <sprint_id> <bare_round> "<artifact_path>"` — with `PROJECT_ID`/`PROJECT_NAME` taken from the actual environment if set at generation time (falling back to an explicit `<PROJECT_ID>`/`<PROJECT_NAME>` placeholder the Product Owner must fill in only when truly unknown), and with `PROJECT_NAME` and `artifact_path` always double-quoted so a spaced value cannot break the command.
   - **`Product Owner Action Required`**: an explicit sentence stating that Product Owner must copy and run the command themselves, and that until they do, this remains only a manual handoff, not a completed Telegram Gate Notification.
   - The existing "Expected Telegram result" line's wording was strengthened to state explicitly that the result is **尚未送出 (not yet sent)** until Product Owner executes the command.
3. **Safety boundary re-verified, unchanged**: `cmd_notify_gate` still has exactly one call site in the entire file (the CLI dispatcher); `_telegram_notification_block()` itself contains no call to `cmd_notify_gate` or any Telegram-sending logic — it is pure text rendering. Both facts are now asserted by tests (26e-mf7, 26e-mf8), not just static comments.
4. Tests added — see Tests section below.

### Files Changed (this Must Fix round)

```text
scripts/review_bridge.sh        — _telegram_notification_block(): added notify-gate command line (with correct bare-round derivation and defensive quoting) and Product Owner Action Required line; strengthened "not yet sent" wording
scripts/test_review_bridge.sh   — extended Test 26 with 12 new sub-assertions (26e-mf1 through 26e-mf8, some with sub-letters) covering the 5 Must Fix test requirements
```

No other file required changes for this Must Fix round. `docs/development/consensus-workflow.md` and `docs/development/telegram-po-gate-notification-specification.md` already documented the Manual-vs-Formal distinction and the notify-gate Execution Policy correctly in the original Sprint-017 round; the gap was purely in the rendered command's actionability and a quoting bug, both in code.

### Tests

```bash
bash scripts/test_review_bridge.sh
```

```text
Results: 223 passed, 0 failed
```

(211 before this Must Fix round + 12 new sub-assertions = 223, zero failures, zero regressions in the pre-existing 211.) New coverage maps directly to the 5 Must Fix Test Requirements:

- Formal PO Gate handoff outputs `Should notify Product Owner: YES` — 26e-mf1.
- Formal PO Gate handoff includes the actual `gate_id` — 26e (pre-existing) + 26e-mf3c.
- Formal PO Gate handoff includes an executable `notify-gate` command — 26e-mf3, 26e-mf3b, 26e-mf3c, 26e-mf3d, 26e-mf3e, 26e-mf4 (quoting safety).
- Chat-based manual handoff remains distinguishable from formal Telegram Gate Notification — 26e-mf2 (formal ones never show the NO/N/A pattern) plus the pre-existing 26k/26l (documentation-level distinction, unchanged this round).
- Telegram notification is not marked completed unless `notify-gate` was executed and delivery verified — 26e-mf6 (wording), plus the pre-existing `Telegram notification received: YES / NO / NOT VERIFIED` field in the Flow Deviation Check (`consensus-workflow.md`, unchanged this round).

### Telegram / notify-gate Safety Check

- Did Claude execute notify-gate: NO
- Did Claude trigger Telegram: NO
- Is notify-gate still Product Owner controlled: YES
- `reviews/notification_history.jsonl` record count: unchanged (still 2, both pre-dating this Sprint) — confirmed via `wc -l` before and after this Must Fix round.
- `configs/n8n/*.json`: unchanged (`git diff --stat configs/n8n/` empty).
- `git add` / `git commit` / `git push`: none executed (`git status --short` shows only the two files above as modified since the prior round; `git diff --cached --name-only` is empty).

## Handoff to Codex

Next Actor: Codex

Recommended Execution Mode: Codex Review Mode

Per this Sprint's explicit constraints, Codex Review is **not** triggered automatically by this report — Product Owner decides when to advance to Codex Review Mode. Product Owner may now re-attempt Validation: the Handoff Package generated by `check` for any in-flight Sprint will include a copy-pasteable `notify-gate` command that, if Product Owner chooses to run it themselves, will produce a real Telegram Gate Notification for that Sprint's current Gate.

(See "Sprint-017 Must Fix Round 2" below for the latest state as of the Telegram Gate Validation Precheck re-run.)

## Sprint-017 Must Fix Round 2 (Telegram Gate Validation Precheck: FAIL → PASS)

### Must Fix Round 2 Root Cause

The Precheck reported: "no concrete sprint-017 001 notify-gate command was found in reviews/sprint-017/round-001, scripts, or docs. Current repo only contains the renderer/template form." This was accurate and distinct from the Round 1 fix.

Round 1 fixed the **renderer** (`_telegram_notification_block()` in `scripts/review_bridge.sh`) so that *whenever it runs*, it produces an actionable, correctly-quoted, copy-pasteable command. Round 1's own tests (26e-mf3 etc.) proved this by invoking the renderer inside a temp `REVIEWS_OVERRIDE` directory — which is exactly right for testing the renderer's logic, but it means the fix's *evidence* only ever existed inside disposable test directories, never in the real repository. Nothing in Round 1 actually ran the renderer against real Sprint-017 data and saved the result under `reviews/sprint-017/round-001/`. So a Precheck that scans the real repository for a concrete, already-materialized command correctly found nothing — the fix was real and tested, but its output had never been produced and committed to disk for this specific Sprint.

A secondary consideration: the two existing code paths that call `_telegram_notification_block()` (`write_handoff_package_claude_to_codex` / `write_handoff_package_codex_to_claude`, both invoked only from `cmd_check`) only cover 2 of the 21 canonical Product Owner Gates (`claude_implementation_report_acceptance` and `codex_review_result_decision`). Sprint-017's actual current Gate — Codex Final Review has already returned PASS (`reviews/sprint-017/round-001/codex_final_review.md`), and Product Owner is now attempting Validation — corresponds to `product_owner_validation_approval`, a Gate neither of those two functions renders for. Running `cmd_check` against the real Sprint-017 directory would therefore not have produced the *correct* current-Gate command anyway; it would have produced a stale one for an earlier stage.

### Files Changed (this Must Fix Round 2)

**Created:**

```text
reviews/sprint-017/round-001/formal_gate_handoff.md   — concrete, materialized artifact (see below)
```

**Modified:**

```text
scripts/test_review_bridge.sh   — new Test 27 (12 sub-assertions, 27a-27l) validating the concrete artifact; new REAL_HISTORY_COUNT_BEFORE snapshot near the top of the file so 27l can assert no real notify-gate execution happened during the whole test run, without hardcoding a count that would go stale
```

`scripts/review_bridge.sh` was **not** modified in this round — the renderer itself (fixed in Round 1) was already correct; the gap was that its output had never been generated and saved for the real Sprint-017.

### Exact Generated Formal Handoff Artifact Path

```text
reviews/sprint-017/round-001/formal_gate_handoff.md
```

This file was generated by extracting only `_full_reading_list_zh()` and `_telegram_notification_block()` from `scripts/review_bridge.sh` into an isolated, sourced shell snippet (never sourcing or executing the file's CLI dispatcher), then invoking `_telegram_notification_block("product_owner_validation_approval", "sprint-017", "round-001", "reviews/sprint-017/round-001/codex_final_review.md")` with `PROJECT_ID=ai-workspace` and `PROJECT_NAME="AI Workspace"` set, and writing the real output into the file. This guarantees the content is byte-identical to what the real renderer produces — it is not hand-typed prose that could drift from the code.

### Exact notify-gate Command Generated

```bash
PROJECT_ID="ai-workspace" PROJECT_NAME="AI Workspace" ./scripts/review_bridge.sh notify-gate product_owner_validation_approval sprint-017 001 "reviews/sprint-017/round-001/codex_final_review.md"
```

This satisfies all of Must Fix Round 2's item 3 requirements: it visibly includes `./scripts/review_bridge.sh notify-gate`, the actual `gate_id` (`product_owner_validation_approval`, not a placeholder), `sprint-017`, the bare round `001` (not `round-001`, which `validate_round` would reject), and the actual `artifact_path`. `PROJECT_ID`/`PROJECT_NAME` are filled with this project's real, already-known values (not left as `<PROJECT_ID>`/`<PROJECT_NAME>` placeholders), since both were available at generation time and the command is more directly usable this way — per item 6, if they had been unresolvable they would have remained as clearly-labeled placeholders with an explanation of what to replace, as the underlying renderer already does by default.

### Test Result

```bash
bash scripts/test_review_bridge.sh
```

```text
Results: 235 passed, 0 failed
```

(223 before this round + 12 new Test 27 sub-assertions = 235, zero failures, zero regressions.) Test 27 gives the Precheck a durable, automated fixture check going forward: 27a confirms the artifact file exists; 27b-27j confirm the concrete command and all required Telegram Notification fields are present with real (non-placeholder) values; 27k confirms the gate_id is one of the 21 canonical IDs; 27l confirms — by comparing a snapshot taken before any test in the suite ran to the count after — that no part of this Must Fix Round 2 (including generating the artifact itself) ever executed a real `notify-gate` against the actual repository.

### Precheck Result

```text
PRECHECK PASS
```

Manually re-run by the same method the Precheck described (searching `reviews/sprint-017/round-001`, `scripts/`, and `docs/` for a concrete `sprint-017 001` `notify-gate` command):

```bash
grep -rn "notify-gate .*sprint-017 001" reviews/sprint-017/ scripts/ docs/
```

Result: found in `reviews/sprint-017/round-001/formal_gate_handoff.md` (the artifact created this round) and in `scripts/test_review_bridge.sh` (the new Test 27 fixture assertion) — both containing the real gate_id, `sprint-017`, `001`, and a real artifact_path.

### Telegram / notify-gate Safety Check

- Did Claude execute notify-gate: NO — the concrete command was produced by directly invoking only the two pure-text-rendering functions (`_full_reading_list_zh`, `_telegram_notification_block`) in an isolated sourced shell, never by running `review_bridge.sh notify-gate` or any other Review Bridge command.
- Did Claude trigger Telegram: NO.
- Is notify-gate still Product Owner controlled: YES — `cmd_notify_gate` still has exactly one call site (the CLI dispatcher), confirmed again by Test 26h and 26e-mf7 in this same run.
- `reviews/notification_history.jsonl` record count: unchanged before and after this entire Must Fix Round 2 (confirmed both manually via `wc -l` and automatically via Test 27l's before/after snapshot comparison).
- `configs/n8n/*.json`: unchanged (`git diff --stat configs/n8n/` empty).
- `git add` / `git commit` / `git push`: none executed (`git diff --cached --name-only` empty; `git status --short` shows only the one new file and one modified test file for this round).
- No unrelated dirty/untracked file was touched.

## Sprint-017 Must Fix Round 3 (Product Owner Validation blocked again after receiving the real Telegram notification)

Product Owner actually executed the `notify-gate` command from Round 2 and received a real Telegram message (`reviews/notification_history.jsonl` now has a third record: `gate_id=product_owner_validation_approval`, `delivery_status=delivered`). Reading that real message surfaced two further gaps that only became visible once real content was received.

### Blocker 1: Handoff Package only referenced the artifact path, not its content

**Root cause**: `cmd_notify_gate()`'s `handoff_package` variable (`scripts/review_bridge.sh`) rendered `請閱讀：\n- ${artifact_path}` — a path reference only. This is a different code path from Round 1/2's fix, which only touched `_telegram_notification_block()` (used by the Sprint-010 `write_handoff_package_*` functions). Round 1/2 made the *notify-gate command itself* actionable; it never touched what the *already-delivered* Gate Notification Package contains. Product Owner correctly pointed out that once the message is in Telegram, forcing them to open the repository to read the referenced file defeats the purpose of a mobile-friendly notification.

**Fix**: `cmd_notify_gate()` now reads the artifact's real content (`cat "$abs_artifact_path"`, the same absolute path already resolved and validated earlier in the function — a direct, unmodified read, consistent with Artifact First / Sprint-013 Must Fix 1) and inlines it inside the Handoff Package block, wrapped in explicit `===== BEGIN ARTIFACT CONTENT (...) =====` / `===== END ARTIFACT CONTENT =====` markers. The path reference (`請閱讀：- <path>`) is kept alongside the inlined content for traceability.

**Chunking**: no new chunking logic was needed. The entire rendered Notification Package (now including the larger inlined content) still passes through the existing `_notify_split_for_telegram` character-based chunker (unchanged, Sprint-013 Must Fix 1), which already splits strictly in order and sends chunks as sequential Telegram messages. This is now explicitly documented in `docs/development/telegram-po-gate-notification-specification.md` Section 20.2, including the disclosed limitation that a very long artifact may be split mid-line across message boundaries (never reordered, never truncated, never summarized).

### Blocker 2: Only one Gate (`product_owner_validation_approval`) had real validation evidence

**Root cause**: the only end-to-end proof available was Product Owner's single live execution against one gate_id. Nothing demonstrated that the other 20 canonical gates would behave correctly (real gate_id, correct command, inline content, no placeholders) if Product Owner tried them.

**Fix**: added Test 28 to `scripts/test_review_bridge.sh` — a contract test that iterates all 21 canonical `gate_id`s (read from the same `GATE_WHITELIST` in `scripts/review_bridge.sh`, not a second hand-maintained list) and, for each one, verifies:

- `cmd_notify_gate` produces a package containing the gate's own real `gate_id`, `sprint_id`, `round_id`, `artifact_path`, and — proving Blocker 1's fix generalizes — the actual inlined artifact content (a distinctive marker string unique to this test run, not just the path).
- `_telegram_notification_block()`, called directly for that `gate_id` (extracted into an isolated sourced file, never the CLI dispatcher — same technique as Round 2's `formal_gate_handoff.md`), produces: a non-placeholder `gate_id`, an executable `notify-gate command` using the correct `gate_id`/`sprint_id`/bare-round order, never the malformed `round-NNN` CLI argument, and a `Product Owner Action Required` line.

### Files Changed (this Must Fix Round 3)

```text
scripts/review_bridge.sh                                          — cmd_notify_gate(): inline real artifact content into the Handoff Package block, delimited by BEGIN/END markers
scripts/test_review_bridge.sh                                     — new Test 28 (9 sub-assertions, 28a-28i) contract-testing all 21 canonical gates
docs/development/telegram-po-gate-notification-specification.md   — new Section 20: inline-content rule + documented safe-chunking behavior
docs/development/consensus-workflow.md                             — Handoff Package Standard section: added a cross-reference note that inline content (not a path reference) is required, pointing to the Telegram spec's Section 20
```

### Test Result

```bash
bash scripts/test_review_bridge.sh
```

```text
Results: 244 passed, 0 failed
```

(235 before this round + 9 new Test 28 sub-assertions = 244, zero failures, zero regressions.)

### Precheck Result

```text
PRECHECK PASS
```

Re-verified: `grep -n "BEGIN ARTIFACT CONTENT" scripts/review_bridge.sh` finds the new inline-content marker in `cmd_notify_gate()`; a manual smoke test (isolated temp directory, not the real repo) confirmed a sample artifact's real content appears between the BEGIN/END markers in the generated package for `product_owner_validation_approval`; Test 28 automates this same proof for all 21 canonical gates.

### Telegram / notify-gate Safety Check

- Did Claude execute notify-gate: NO — all verification (manual smoke test and Test 28) used `REVIEWS_OVERRIDE`-isolated temporary directories with `NOTIFICATION_ENABLED` unset.
- Did Claude trigger Telegram: NO.
- Is notify-gate still Product Owner controlled: YES — `cmd_notify_gate` still has exactly one call site (the CLI dispatcher); unchanged this round.
- `reviews/notification_history.jsonl`: now has 3 records total — the third one (`gate_id=product_owner_validation_approval`, `delivery_status=delivered`) is Product Owner's own real execution from between Round 2 and Round 3, not something Claude produced. This Round's test suite captures the record count *before* the suite runs and asserts it is unchanged *after* (Test 27l and the new Test 28i), so the check adapts correctly to Product Owner's real activity instead of relying on a hardcoded number.
- `configs/n8n/*.json`: unchanged.
- `git add` / `git commit` / `git push`: none executed; no unrelated dirty/untracked file was touched.

## Sprint-017 Must Fix Round 4 (Product Owner Validation blocked a third time: Chinese summary missing + overstated coverage risk)

Product Owner ran `notify-gate` twice more against the real gate (`reviews/notification_history.jsonl` now has a 4th record, both new ones for `product_owner_validation_approval`), and raised two further blockers after actually reading the delivered content.

### Blocker 1: inlined content was mostly English, no Chinese decision summary

**Root cause**: Round 3 correctly inlined the raw artifact content, but the artifact Product Owner pointed `notify-gate` at (`codex_final_review.md`) is Codex-authored, in English. Product Owner had to read and translate that content themselves before they could decide anything — exactly the friction the whole notify-gate feature was meant to remove.

**Fix**: `cmd_notify_gate()` (`scripts/review_bridge.sh`) gains an optional 5th positional CLI argument, `summary_path`:

```bash
./scripts/review_bridge.sh notify-gate <gate_id> <sprint_id> <round> <artifact_path> [summary_path]
```

- When given, the referenced file's content is inlined **verbatim, in full**, under a new `🇹🇼 Product Owner Summary（繁體中文摘要，請先讀這裡）` heading, placed **before** the existing `===== BEGIN ARTIFACT CONTENT =====` block — so Product Owner reads the Chinese decision summary first, with the raw (possibly English) artifact still available below as evidence.
- When omitted, behavior is **exactly** what it was before this round — no summary section is rendered at all. This is a deliberate backward-compatible design: `cmd_notify_gate` is generic, cross-Sprint infrastructure, and it cannot itself know Sprint-specific facts like "Codex Final Review result: PASS" or "remaining Must Fix: none" — those facts belong in a separately-authored summary file, not hardcoded into shared code.
- A missing `summary_path` fails loudly (`Summary artifact not found: <path>`), matching how a missing `artifact_path` already behaves — never silently skipped.
- The required Chinese summary content (Sprint ID/round, gate_id, Gate name, current status, Codex Final Review result, remaining Must Fix, Should Fix, test result, 21-Gate contract coverage, live delivery coverage, Product Owner's next decision, and whether Telegram delivery is pending or already sent) is documented as a content contract in `docs/development/telegram-po-gate-notification-specification.md` Section 21.2, and instantiated for Sprint-017's actual current situation in the new `reviews/sprint-017/round-001/po_summary_zh.md`.

**Concrete command Product Owner can now run** to receive the Chinese summary for the current Gate:

```bash
PROJECT_ID="ai-workspace" PROJECT_NAME="AI Workspace" ./scripts/review_bridge.sh notify-gate product_owner_validation_approval sprint-017 001 "reviews/sprint-017/round-001/codex_final_review.md" "reviews/sprint-017/round-001/po_summary_zh.md"
```

### Blocker 2: coverage claims did not distinguish contract testing from live delivery

**Root cause**: after Round 3's Test 28 (contract-testing all 21 gates), there was a real risk of that automated, repeatable test coverage being mistaken for — or worded as — proof that all 21 gates have been live-delivered to Telegram. Only one gate (`product_owner_validation_approval`) has ever actually been executed against real Telegram infrastructure by Product Owner.

**Fix**: created `reviews/sprint-017/round-001/gate_notification_coverage_report.md`, a table listing all 21 canonical `gate_id`s with four separate columns — Contract Validation, Generated Command Validation, Inline Content Validation, Live Delivery — sourced respectively from Test 28 (all `PASS`, automated) and from `reviews/notification_history.jsonl` (only `product_owner_validation_approval` is `PASS`; the other 20 are explicitly `NOT TESTED`, never inferred as passing). `docs/development/telegram-po-gate-notification-specification.md` Section 21.3 now states explicitly: "不得宣稱「21 Gate live delivery: PASS」" unless every gate has its own `delivered` record.

### Files Changed (this Must Fix Round 4)

```text
scripts/review_bridge.sh                                          — cmd_notify_gate(): optional summary_path 5th argument; inlines Chinese summary before raw artifact content
scripts/test_review_bridge.sh                                     — new Test 29 (10 sub-assertions, 29a-29g with sub-parts) covering backward compatibility, ordering, and missing-summary error handling
docs/development/telegram-po-gate-notification-specification.md   — new Section 21: Product Owner Summary requirement, content contract, and the contract-vs-live-delivery distinction (21.3)
```

**Created:**

```text
reviews/sprint-017/round-001/po_summary_zh.md                       — the actual Traditional Chinese Product Owner Summary for Sprint-017's current Gate
reviews/sprint-017/round-001/gate_notification_coverage_report.md   — Blocker 2's coverage report, all 21 gates, 4 evidence columns kept separate
```

`docs/development/consensus-workflow.md` was reviewed but did not need changes this round — its Handoff Package Standard section already cross-references the Telegram spec's inline-content section generically enough to cover this addition without further edits.

### Test Result

```bash
bash scripts/test_review_bridge.sh
```

```text
Results: 254 passed, 0 failed
```

(244 before this round + 10 new Test 29 sub-assertions = 254, zero failures, zero regressions.)

### Telegram / notify-gate Safety Check

- Did Claude execute notify-gate: NO — the manual smoke test (confirming the Chinese summary renders before the raw artifact content) and Test 29 both used `REVIEWS_OVERRIDE`-isolated temporary directories with `NOTIFICATION_ENABLED` unset.
- Did Claude trigger Telegram: NO.
- Is notify-gate still Product Owner controlled: YES — unchanged; `cmd_notify_gate` still has exactly one call site.
- `reviews/notification_history.jsonl`: unaffected by this round's work (Test 29g re-confirms the before/after snapshot; the file's growth from 3 to 4 records reflects Product Owner's own additional real execution between rounds, not anything Claude did).
- `configs/n8n/*.json`: unchanged.
- `git add` / `git commit` / `git push`: none executed; no unrelated dirty/untracked file was touched.

## Sprint-017 Must Fix Round 5 (Product Owner Validation blocked a fourth time: no copy-pasteable next-actor package)

### Root Cause

Product Owner received the Round 4 notification (Chinese summary + raw artifact evidence) and correctly noted it still said "確認後可進入 Git Review 階段" without actually providing the Codex Git Review Handoff Package that step requires — forcing a return to ChatGPT to obtain it, defeating the "receive Telegram notification, copy, hand to next AI actor" usability goal.

### Fix

`cmd_notify_gate()` (`scripts/review_bridge.sh`) gains an optional 6th positional CLI argument, `next_handoff_path`:

```bash
./scripts/review_bridge.sh notify-gate <gate_id> <sprint_id> <round> <artifact_path> [summary_path] [next_handoff_path]
```

- When given, the file's content is inlined verbatim under a new `🤖 Next AI Handoff Package` heading. Omitting it preserves exact prior behavior (backward compatible).
- A missing `next_handoff_path` fails loudly (`Next AI Handoff Package artifact not found: <path>`), matching how missing `artifact_path`/`summary_path` already behave.
- The heading deliberately does **not** say "轉交給 `${GATE_NEXT_ACTOR}`": for `product_owner_validation_approval`, `GATE_NEXT_ACTOR` is itself `Product Owner` (the canonical metadata's immediate-next-actor value), but the real AI actor a specific Next AI Handoff Package targets a few steps ahead (here, Codex for Git Review) can differ. The inlined content states its own `Target AI`, matching Sprint-010's existing convention, instead of the heading asserting a name that could be wrong.
- The whole "📦 Handoff Package" block was reorganized (requirement 4) into 4 explicitly labeled, fixed-order sections: 🇹🇼 Product Owner Summary → ✅ Product Owner Decision Options → 🤖 Next AI Handoff Package → 📄 Raw Artifact Evidence.
- Created the real content for Sprint-017's current Gate: `reviews/sprint-017/round-001/codex_git_review_handoff_zh.md`, a complete Codex Git Review Handoff Package in Traditional Chinese covering all of requirement 3's required elements (full reading list, Traditional Chinese output rule, Context Completeness Check requirement, task objective, review target, allowed/prohibited files, repository hygiene checks, runtime evidence exclusion checks, exact report path `reviews/sprint-017/round-001/codex_git_review.md`, and the standard restrictions).

### Debugging Note (test failure found and fixed before completion)

While adding Test 30, one assertion (`30a-1`, checking that omitting `next_handoff_path` renders no "Next AI Handoff Package" section) initially failed. Root cause: the test's own artifact fixture text — inlined verbatim into "📄 Raw Artifact Evidence" by Round 3's own feature — happened to contain the English sentence "This must remain present even after adding the Next AI Handoff Package," which coincidentally matched the bare-phrase substring check. This was a false positive in the *test*, not a defect in `cmd_notify_gate`: manually re-running the same `notify-gate` invocation confirmed the actual generated package never contained a `🤖 Next AI Handoff Package` heading when `next_handoff_path` was omitted.

Fix applied to the test only: reworded the fixture text to avoid the coincidental phrase, and tightened the 30a-1 assertion to match the exact emoji-prefixed heading (`🤖 Next AI Handoff Package`) rather than the bare phrase, so future fixture wording cannot trigger the same false positive. No `cmd_notify_gate` code changed as part of this fix — only `scripts/test_review_bridge.sh`. A temporary `echo ... >&2` debug line was added directly in the test file to inspect the real generated content, then removed immediately after the root cause was confirmed; no debug output remains in the final file, and no scratch file was left in the repository or the session scratchpad.

### Files Changed (this Must Fix Round 5)

```text
scripts/review_bridge.sh                                          — cmd_notify_gate(): optional next_handoff_path 6th argument; restructured Handoff Package into 4 labeled sections
scripts/test_review_bridge.sh                                     — new Test 30 (24 sub-assertions, 30a-30l with sub-parts); one fixture wording fix + one assertion tightening (see Debugging Note)
docs/development/telegram-po-gate-notification-specification.md   — new Section 22: Next AI Handoff Package requirement, 4-section notification layout, required content list
docs/development/consensus-workflow.md                             — Handoff Package Standard section: added a cross-reference note for the Next AI Handoff Package requirement
```

**Created:**

```text
reviews/sprint-017/round-001/codex_git_review_handoff_zh.md   — the real Codex Git Review Handoff Package for Sprint-017's current Gate, in Traditional Chinese
```

### Test Result

```bash
bash scripts/test_review_bridge.sh
```

```text
Results: 278 passed, 0 failed
```

(254 before this round + 24 new Test 30 sub-assertions = 278, zero failures, zero regressions. The suite was run clean — no debug output, no temporary files.)

### Telegram / notify-gate Safety Check

- Did Claude execute notify-gate: NO — the manual smoke test and Test 30 both used `REVIEWS_OVERRIDE`-isolated temporary directories with `NOTIFICATION_ENABLED` unset.
- Did Claude trigger Telegram: NO.
- Is notify-gate still Product Owner controlled: YES — unchanged; `cmd_notify_gate` still has exactly one call site (the CLI dispatcher).
- `reviews/notification_history.jsonl`: unaffected by this round's work (Test 30l re-confirms the before/after snapshot; the file continuing to grow — now 5 records — reflects Product Owner's own real activity, not anything Claude did).
- `configs/n8n/*.json`: unchanged.
- `git add` / `git commit` / `git push`: none executed; no unrelated dirty/untracked file was touched.

### Repository Hygiene Check

- No debug/temporary file remains: `grep -rn "TEMP-DEBUG" scripts/ reviews/sprint-017/` returns nothing; the one temporary debug `echo` line added mid-investigation was removed before this report was finalized.
- No leftover scratch script: a `rb_funcs.sh` file left over in the session scratchpad from an earlier Must Fix round (Round 2) was also found and deleted during this round's cleanup pass, even though it predated this round's own work.
- `git status --short` shows only the files listed under "Files Changed" above as newly modified/created for this round; all previously-known unrelated dirty/untracked files remain untouched.
- No `git add`, `git commit`, or `git push` was executed at any point.

## Sprint-017 Must Fix Round 6：Telegram Content Mode / Copyability Improvement

### Root Cause

Product Owner 實際在手機上收到 Round 5 的 Telegram 通知後回報：內容太長，被 Telegram 切成很多則訊息，導致真正要複製轉交的「🤖 Next AI Handoff Package」變得不好操作。根本原因是 Round 3–5 的設計把「📄 Raw Artifact Evidence」（完整原始 artifact 原文，例如整份英文的 `codex_final_review.md`）**預設一律內嵌**在 Notification Package 裡，而且緊跟在 Next AI Handoff Package 之後——原始證據常常很長，把真正要複製的內容淹沒、拉長、切散到多則訊息中，違背了「Product Owner 收到通知後應能快速、乾淨地複製轉交」的可用性目標。

### 修正內容

在 `cmd_notify_gate()`（`scripts/review_bridge.sh`）新增 **Telegram Content Mode** 概念，由環境變數 `TELEGRAM_CONTENT_MODE` 控制，不合法的值會直接失敗（`Invalid TELEGRAM_CONTENT_MODE`），不會靜默 fallback。同時新增「📎 Evidence Reference」區塊（任何 mode 都會出現，只列路徑不內嵌內容），並把整個「📦 Handoff Package」內容重新排序為固定順序：🇹🇼 Product Owner Summary → ✅ Product Owner Decision Options → 🤖 Next AI Handoff Package（summary mode 不出現）→ 📎 Evidence Reference → 📄 Raw Artifact Evidence（只有 full mode 才出現，且明確標示「完整原文，內容可能很長」）。這個順序確保 Raw Artifact Evidence 一定排在 Next AI Handoff Package 之後，不會插在中間或前面。

### Content Mode 設計

| Mode | Summary | Decision Options | Next AI Handoff Package | Evidence Reference | 完整 Raw Artifact Evidence |
|---|---|---|---|---|---|
| `summary` | ✅ | ✅ | ❌ | ✅ | ❌ |
| `handoff`（**預設**） | ✅ | ✅ | ✅ | ✅ | ❌ |
| `full` | ✅ | ✅ | ✅ | ✅ | ✅ |

### 預設模式為何

**`handoff`**——未設定 `TELEGRAM_CONTENT_MODE` 時，`cmd_notify_gate()` 內部以 `content_mode="${TELEGRAM_CONTENT_MODE:-handoff}"` 明確預設為 `handoff`。這代表 Product Owner 執行 Round 5/6 文件中給的範例指令（不加任何環境變數）時，預設輸出**會**包含 🇹🇼 Product Owner Summary、🤖 Next AI Handoff Package、📎 Evidence Reference、🧾 Delivery Metadata，**不會**包含 `===== BEGIN ARTIFACT CONTENT =====` 或整份 `codex_final_review.md` 原文——已用手動 smoke test 與自動化 Test 31 雙重驗證。

### Full Evidence Opt-in 說明

若 Product Owner 需要完整原始佐證，可自行加上環境變數手動啟用，例如：

```bash
TELEGRAM_CONTENT_MODE=full PROJECT_ID="ai-workspace" PROJECT_NAME="AI Workspace" \
  ./scripts/review_bridge.sh notify-gate product_owner_validation_approval sprint-017 001 \
  "reviews/sprint-017/round-001/codex_final_review.md" \
  "reviews/sprint-017/round-001/po_summary_zh.md" \
  "reviews/sprint-017/round-001/codex_git_review_handoff_zh.md"
```

這是 opt-in，不是預設行為；`summary`/`full` 模式的內容規則、切分機制（沿用既有 `_notify_split_for_telegram`，未修改）皆已文件化在 `docs/development/telegram-po-gate-notification-specification.md` 第 23 節。

### Files Changed（本回合）

```text
scripts/review_bridge.sh                                          — cmd_notify_gate()：新增 TELEGRAM_CONTENT_MODE 驗證、Evidence Reference 區塊、依 mode 條件式組裝 Handoff Package
scripts/test_review_bridge.sh                                     — 新增 Test 31（24 項子案例）；修正 Test 28/29/30 三處既有呼叫，明確加上 TELEGRAM_CONTENT_MODE=full（因為預設行為改變，原本驗證「一律內嵌完整原文」的既有測試需要明確指定 full mode 才能繼續成立，這是預期的測試遷移，不是產品缺陷）
docs/development/telegram-po-gate-notification-specification.md   — 新增第 23 節：Telegram Content Mode / Copyability Improvement
docs/development/consensus-workflow.md                             — Handoff Package Standard 區塊新增 Round 6 交叉引用說明
```

未修改 `docs/development/execution-permission-policy.md`、`docs/development/development-workflow.md`、`docs/development/product-owner-gate-metadata.md`——本回合改動範圍完全落在既有的 Sprint-017 檔案清單內，未擴大範圍。

### Tests

```bash
bash scripts/test_review_bridge.sh
```

```text
Results: 302 passed, 0 failed
```

（278（Round 5 結束時）+ 24 項新增 Test 31 子案例 = 302，零失敗。Test 28/29/30 中原本 3 處因應新預設行為而更新為明確 `TELEGRAM_CONTENT_MODE=full` 的呼叫，修正後同樣全數通過，零迴歸。）Test 31 涵蓋 Round 6 要求的全部 12 項：預設模式為 handoff、預設/handoff mode 含 Summary、含 Next AI Handoff Package、含 Evidence Reference、不含 BEGIN/END ARTIFACT CONTENT、full mode 含 BEGIN/END ARTIFACT CONTENT、summary mode 含 Summary、summary mode 不含 Next AI Handoff Package、summary mode 不含 BEGIN/END ARTIFACT CONTENT、不合法 mode 會 fail loudly、mode 不改變 notify-gate safety boundary（`cmd_notify_gate` 仍只有一個呼叫點）、全程未觸發 Telegram 也未新增真實 `reviews/notification_history.jsonl` 紀錄（前後筆數快照比對）。

### Telegram / notify-gate Safety Check

- 是否執行 notify-gate：否——手動 smoke test 與 Test 31 皆使用 `REVIEWS_OVERRIDE` 隔離的暫存目錄，`NOTIFICATION_ENABLED` 全程未設定。
- 是否觸發 Telegram：否。
- notify-gate 是否仍由 Product Owner 掌控：是——`cmd_notify_gate` 仍只有一個呼叫點（CLI dispatcher），Test 31i 重新確認。
- `reviews/notification_history.jsonl`：本回合測試未新增任何真實紀錄（Test 31j 以本輪測試開始前的筆數快照比對，確認前後一致）；檔案從 5 筆長到 6 筆，反映的是 Product Owner 自己在本回合期間的真實操作，不是我造成的。
- `configs/n8n/*.json`：未變。
- 全程未執行 `git add`、`git commit`、`git push`；未處理任何 unrelated dirty/untracked files；未修改 Sprint-013/014/015/016 已 CLOSED artifacts；`reviews/notification_history.jsonl` 未被納入任何 commit 動作（本回合根本未執行任何 git 寫入操作）。

### Repository Hygiene Check

- `git status --short` 只顯示本回合實際修改/新增的 4 個檔案（見上方 Files Changed），其餘既有 dirty/untracked 檔案維持原狀，未被觸碰。
- `git diff --cached --name-only` 為空，確認沒有任何檔案被 stage。

### Known Limitations

1. `📎 Evidence Reference` 只會列出 `notify-gate` 本身已知的通用參數路徑（Source Artifact、Product Owner Summary、Next AI Handoff Package、Notification History），不會自動列出特定 Sprint 才有的額外檔案（例如 `gate_notification_coverage_report.md`）。若某個 Sprint 想讓 Evidence Reference 也涵蓋這類額外路徑，需要把它寫進 `summary_path` 或 `next_handoff_path` 指向的檔案內容裡，`cmd_notify_gate` 本身不會臆測。這是延續 Round 4/5 已確立的「通用基礎設施不硬編特定 Sprint 事實」設計原則，非本回合新增的限制，這裡一併說明以避免誤解。
2. Content Mode 的選擇（summary/handoff/full）不影響、也不能取代第 21.3 節已確立的 contract coverage 與 live delivery 必須分開判斷的原則——這點已在文件第 23.5 節重申。

## Sprint-017 Must Fix Round 7：AI Handoff Standalone Message / Copy Boundary UX Improvement

### Root Cause

Round 6 完成後，Product Owner 實際在手機上使用時仍回報：即使預設不再內嵌完整原文，Telegram 若整份 Notification Package 內容一起用字元數盲切送出，「🤖 Next AI Handoff Package」後面仍可能接著出現「📎 Evidence Reference」或其他非 AI 指令內容，逼得 Product Owner 得自己判斷哪一段才是真正要複製轉交的指令，不符合「收到通知就能直接整段複製」的需求。根本原因是 Round 3–6 的 Telegram 送出邏輯只有「把整個檔案依字元數切成連續訊息」這一種機制，從未依「邏輯區塊」（摘要／決策／交接指令／證據／metadata）分開處理。

### 修正內容

在 `cmd_notify_gate()` 新增 **section-aware 訊息拆分**：不再把整份 Notification Package 丟給 `_notify_split_for_telegram` 盲切，而是先依邏輯區塊組成獨立的訊息內容，各自送出。新增 `_notify_gate_extract_target_ai()` 輔助函式，從 `next_handoff_path` 內容自己宣告的「Target AI」解析出實際目標 AI（例如 `Codex`），用於組成固定格式的 copy boundary marker；若解析不到 Target AI 宣告，或訊息內容加上 marker 後超過安全單訊息長度（3500 字元），一律直接 fail loudly，不默默切成兩則。

### Section-aware Split 設計

依 Content Mode 送出的訊息組合：

| Content Mode | Message 1 | Message 2 | Message 3 | Message 4+ |
|---|---|---|---|---|
| `summary` | Header + Summary + Decision Options | （不出現） | Evidence Reference + Delivery Metadata | （不出現） |
| `handoff`（預設） | Header + Summary + Decision Options | 🤖 Next AI Handoff（僅 copy block） | Evidence Reference + Delivery Metadata | （不出現） |
| `full` | Header + Summary + Decision Options | 🤖 Next AI Handoff（僅 copy block） | Evidence Reference + Delivery Metadata | 📄 Raw Artifact Evidence（可能再切成多則） |

寫入磁碟的 `reviews/<sprint>/round-<round>/notifications/gate-<gate_id>.md` 檔案內容形狀不變（仍是 Round 6 的單一完整檔案），改變的只是「這份內容如何被分組送到 Telegram」。

### Next AI Handoff Standalone Message 設計

Message 2（只有 handoff/full mode 且有提供 `next_handoff_path` 才出現）只包含：copy boundary marker + `next_handoff_path` 原文內容，不含 Product Owner Summary、Decision Options、Evidence Reference、Delivery Metadata、Raw Artifact Evidence 中任何一項——已用 Test 32c 逐一驗證這 6 種雜訊皆不存在。

### Copy Boundary Marker

```text
===== BEGIN COPY TO <TARGET_AI> =====
<next_handoff_path 原文內容>
===== END COPY TO <TARGET_AI> =====
```

`<TARGET_AI>` 從 `next_handoff_path` 內容自己的「Target AI」宣告解析、轉大寫；以 Sprint-017 目前 Gate 而言即為 `CODEX`。已重新整理 `reviews/sprint-017/round-001/codex_git_review_handoff_zh.md`（Option A：從 5120 字元精簡到 3258 字元，保留全部必要內容：Target AI、語言規則、完整必讀清單、Context Completeness Check 要求、任務目標、Allowed/Prohibited Files、Repository Hygiene / Runtime Evidence Exclusion Checks、產出報告路徑、嚴格限制、Copyable Prompt），確保它落在安全單訊息長度內；同時在 `cmd_notify_gate()` 實作長度檢查（Option B）作為未來的安全網，若日後有人準備了過長的 handoff 內容，會直接 fail loudly 而不是默默截斷或分段。

### Files Changed（本回合）

```text
scripts/review_bridge.sh                                          — 新增 _notify_gate_extract_target_ai()；cmd_notify_gate() 新增 Target AI 解析、單訊息長度檢查（fail loudly）、header_zh/delivery_metadata_zh/decision_options_zh 拆分為獨立變數、Telegram 送出邏輯改為 section-aware 分組傳送
scripts/test_review_bridge.sh                                     — 新增 Test 32（25 項子案例）；修正既有 Test 24p 改用 subset 比對法（因為送出方式從單一檔案位元組比對改為多則訊息分組傳送，原本的 byte-for-byte diff 已不適用，改為驗證「送出的每一行都真的來自原始檔案，沒有捏造」）；修正 Test 24p 的假 curl stub 從 $RANDOM 命名改為決定性遞增編號（原本用 $RANDOM 產生檔名有極小機率碰撞、導致訊息互相覆寫、測試 flaky，已用連續執行 5 次確認修正後穩定）
docs/development/telegram-po-gate-notification-specification.md   — 新增第 24 節：AI Handoff Standalone Message / Copy Boundary UX Improvement
docs/development/consensus-workflow.md                             — Handoff Package Standard 區塊新增 Round 7 交叉引用說明
```

**修改（精簡）：**

```text
reviews/sprint-017/round-001/codex_git_review_handoff_zh.md   — 從 5120 字元精簡到 3258 字元，內容不變質但更精簡，確保落在安全單訊息長度內（Option A）
```

### Tests

```bash
bash scripts/test_review_bridge.sh
```

```text
Results: 327 passed, 0 failed
```

（302（Round 6 結束時）+ 25 項新增 Test 32 子案例 = 327，零失敗。已連續執行 5 次確認結果穩定，無 flaky。）Test 32 涵蓋 Round 7 要求的全部 12 項：handoff mode 產生獨立 Next AI Handoff message、該訊息含 BEGIN/END COPY TO CODEX、不含 Evidence Reference、不含 Delivery Metadata、不含 Product Owner Summary、不含 Raw Artifact Evidence、Evidence Reference 出現在另一則訊息、summary mode 不產生該訊息、full mode 的 Raw Artifact Evidence 不會插入該訊息、缺少 next_handoff_path 維持既有 fail loudly、過長內容 fail loudly（並驗證真實 fixture 落在安全長度內）、全程未觸發 Telegram 也未新增真實 `reviews/notification_history.jsonl` 紀錄。

### Telegram / notify-gate Safety Check

- 是否執行 notify-gate：否——所有驗證（手動 smoke test 與 Test 32）皆使用 `REVIEWS_OVERRIDE` 隔離的暫存目錄，搭配假 `curl` stub（從不連接真實網路），`NOTIFICATION_ENABLED`/`TELEGRAM_BOT_TOKEN`/`TELEGRAM_CHAT_ID` 皆為測試用假值。
- 是否觸發 Telegram：否。
- notify-gate 是否仍由 Product Owner 掌控：是——`cmd_notify_gate` 仍只有一個呼叫點，本回合未新增任何自動呼叫路徑。
- `reviews/notification_history.jsonl`：本回合測試未新增任何真實紀錄（Test 32n 以本輪測試開始前的筆數快照比對確認）；檔案從 6 筆長到 9 筆，反映的是 Product Owner 自己在本回合期間的真實操作，不是我造成的。
- `configs/n8n/*.json`：未變。
- 全程未執行 `git add`、`git commit`、`git push`；未處理任何 unrelated dirty/untracked files；未修改 Sprint-013/014/015/016 已 CLOSED artifacts；`reviews/notification_history.jsonl` 未被納入任何 commit 動作。

### Repository Hygiene Check

- `git status --short` 只顯示本回合實際修改/新增的檔案（見上方 Files Changed），其餘既有 dirty/untracked 檔案維持原狀，未被觸碰。
- `git diff --cached --name-only` 為空，確認沒有任何檔案被 stage。

### Known Limitations

1. Target AI 解析（`_notify_gate_extract_target_ai`）依賴 `next_handoff_path` 內容遵循「標題含『Target AI』，下一個非空白行是實際 AI 名稱」的既有慣例（Sprint-010 起沿用）。若未來有人用完全不同的格式撰寫 handoff 內容，會被本回合新增的檢查擋下（fail loudly，要求補上宣告），這是刻意的設計選擇，非疏漏。
2. 單訊息安全長度上限（3500 字元）是沿用既有 `_notify_split_for_telegram` 的切分粒度所選的保守值，並非 Telegram 官方精確的訊息長度限制本身；已確認在此限制下，真實的 `codex_git_review_handoff_zh.md`（3258 字元）與 copy boundary marker 加總後仍有安全餘裕。
3. Section-aware split 只套用在 `cmd_notify_gate`（Sprint-014/016/017 Gate 通知），未套用到 Sprint-013 的 `notify`（事件通知）——符合本 Sprint 一貫「不得修改 Sprint-013 已 CLOSED 程式碼」的範圍限制。
