# Claude Must Fix Report - Sprint-013 Round-001

## Summary

Depending on `reviews/sprint-013/round-001/codex_review.md` (Final Recommendation: FAIL, 4 Must Fix items), this report records the actual fix applied for each Must Fix. All 4 items are resolved: Telegram now delivers the Notification Package artifact verbatim (Artifact First), `Notification Recipient` (always Product Owner) is separated from `Next Actor` (Codex / Claude Code / Product Owner, per event), `docs/development/notification-package-specification.md` has been reconciled with the Sprint-013 `notify` runtime instead of being left as a documented "Known discrepancy," and the generated Notification Package now includes the full, updated 17-field SSOT contract. `docs/development/consensus-workflow.md` and `docs/development/development-workflow.md` were not touched by this Must Fix round. This report was requested as a formal artifact by `reviews/sprint-013/round-001/codex_final_review.md` (Nit 1), which had already independently verified all 4 fixes via source inspection and test output (Final Recommendation: PASS) before this file existed.

## Must Fix Resolution

### Must Fix 1

**Issue (Codex Review):** Telegram delivery built a separately composed `message_text` variable instead of sending the Notification Package artifact's own text, violating Artifact First / SSOT delivery rules.

**Fix:** Removed the separate `message_text` composition path in `cmd_notify` (`scripts/review_bridge.sh`). The Notification Package is now written to `$notif_path` first; a new helper `_notify_split_for_telegram` reads that exact file (never a shell-embedded copy of its content) and splits it into `<=3500`-character literal chunks only if needed for Telegram's message-length limit — no rewriting, summarizing, or reinterpretation occurs. Each chunk is sent via `curl --data-urlencode "text@${chunk_file}"`, which reads and URL-encodes the chunk file's content directly.

**Verification:** Manually confirmed via a stub `curl` that captured the transmitted content and diffed it byte-for-byte against the on-disk Notification Package (identical). Automated in Test 23 (`scripts/test_review_bridge.sh`): "Telegram receives the Notification Package artifact content byte-for-byte (Must Fix 1)."

### Must Fix 2

**Issue (Codex Review):** `target_actor` conflated the Telegram recipient with the next executor. Sprint-013's purpose is to notify Product Owner before the Manual Gate, so the recipient must always be Product Owner, while the next actor (Claude Code / Codex / Product Owner) is a separate, informational concept.

**Fix:** Replaced the single `NOTIFY_TARGET_ACTOR` variable with two distinct concepts in `scripts/review_bridge.sh`:

- `NOTIFY_NOTIFICATION_RECIPIENT` — a constant, always `"Product Owner"`.
- `NOTIFY_NEXT_ACTOR` — resolved per event type by `_notify_resolve_event_meta` (`Codex` for `claude_implementation_done` and `claude_should_fix_done`; `Product Owner` for all other events, including a conservative `Product Owner` for `codex_review_done` per the suggested mapping, since whether a round returns to Claude Code depends on the review outcome, which the generic runtime does not parse).

The Notification Package now renders both as separate sections (`## Notification Recipient`, `## Next Actor`), and the `Product Owner Next Action` / `Copyable Handoff Package` text is phrased from Product Owner's perspective (e.g. "Product Owner should forward this to Codex...") rather than as an instruction addressed directly to Codex or Claude Code.

**Verification:** Test 23 confirms `Notification Recipient = Product Owner` for all 8 event types, and confirms `Next Actor` and `Notification Recipient` are independently represented and can differ (verified for `claude_implementation_done`: recipient `Product Owner`, next actor `Codex`).

### Must Fix 3

**Issue (Codex Review):** `docs/development/notification-package-specification.md` remained the Notification Package SSOT but its Section 2 event model and Section 3 field contract did not match the Sprint-013 runtime; the previously added Sprint-013 note recorded a "Known discrepancy" instead of resolving it.

**Fix:** Updated `docs/development/notification-package-specification.md` in place (no redesign, no new scope):

- Section 2 event table replaced with the exact Sprint-013 8-event whitelist (`claude_implementation_done`, `codex_review_done`, `claude_should_fix_done`, `codex_final_review_done`, `git_review_done`, `commit_done`, `push_done`, `retrospective_done`), explicitly retiring the Sprint-012 draft list.
- New Section 5 ("Notification Recipient vs. Next Actor") formally defines the split introduced in Must Fix 2.
- Section 3 field contract replaced with the 17-field list matching the runtime exactly (see Must Fix 4).
- Section 6 (Delivery Rules) and Section 1 (Core Principle) strengthened to explicitly require verbatim artifact transmission.
- Section 13 changed from "Known discrepancy, not resolved by this note" to "SSOT conflict resolved."
- Stale cross-references (Section 0, 4, 7, 8, 9, 10, 11) that still assumed Sprint-012 draft fields (`Status`, `Package Version`, `Target Actor`, `Copy & Paste Prompt`) or pre-Sprint-013 wiring status were updated for internal consistency.

**Verification:** Test 23 confirms the event list extracted from the specification's Section 2 is identical (as a set) to the `NOTIFY_ALLOWED_EVENTS` whitelist in `scripts/review_bridge.sh`.

### Must Fix 4

**Issue (Codex Review):** The generated Notification Package did not satisfy the SSOT's field contract (missing fields such as `Status`, `Created Time`, `Package Version`, `Summary`, `Next Step`, `Validation Support`, `Artifact Path`, `Delivery Status` in the SSOT-defined form).

**Fix:** Reconciled the field contract (in the same edit as Must Fix 3) to a single authoritative 17-field list adopted by both the specification and the generator: Project ID, Project Name, Sprint ID, Round ID, Event Type, Notification Recipient, Next Actor, Source Artifact Path, Artifact Hash, Deduplication Key, Notification Package Path, Delivery Channel, Delivery Status, Created Time, Product Owner Next Action, Copyable Handoff Package, Delivery Metadata. `cmd_notify` was updated to render every one of these as its own `##` section in the generated package.

`Delivery Status` in the package itself is always rendered as `pending` (the state as of generation time, before any delivery attempt) rather than being mutated after the Telegram send — this is what makes Must Fix 1 possible (the transmitted content is never retroactively different from the on-disk artifact). The authoritative post-attempt outcome (`delivered` / `skipped_duplicate` / `failed` / `disabled`) is recorded only in `reviews/notification_history.jsonl`.

**Judgment call, disclosed:** the Sprint-012 draft fields `Status` (event pass/fail enum), `Package Version`, and `Validation Support` were not carried forward. Reintroducing them would require additional logic (parsing source-artifact pass/fail state, tracking regenerate version counters) beyond what these 4 Must Fix items require, and risked expanding scope. This is recorded in the specification itself (Section 3) as an explicit, deferred decision.

**Verification:** Test 23 confirms all 17 required field headers are present in a generated package.

## Files Changed

```text
scripts/review_bridge.sh                                — Must Fix 1, 2, 4 implementation
scripts/test_review_bridge.sh                            — Test 23 (22 sub-assertions covering all 4 Must Fix items)
docs/development/notification-package-specification.md  — Must Fix 3 (and the field contract for Must Fix 4)
```

No other files were changed during the Must Fix round. `reviews/sprint-013/round-001/architecture.md`, `codex_review.md`, and `codex_final_review.md` were read but not modified.

## Tests

```bash
bash scripts/test_review_bridge.sh
```

```text
Results: 150 passed, 0 failed
```

This matches the test result recorded in `codex_final_review.md`. Coverage added by Test 23 specifically for this Must Fix round:

- Telegram-transmitted content equals the Notification Package artifact byte-for-byte.
- `Notification Recipient` is `Product Owner` for all 8 event types.
- `Next Actor` is a distinct, independently-verifiable field.
- All 17 SSOT-required fields are present in a generated package.
- The event whitelist is identical between the specification and the runtime.

No existing test was removed or weakened; the full pre-existing suite (128 tests prior to this round) continues to pass unchanged.

## Out of Scope Items Not Performed

Per the Must Fix instructions, the following were explicitly not done:

- No redesign of the Notification system or Notification Package Specification beyond the 4 Must Fix items.
- No expansion to a multi-channel notification platform (Telegram remains the only delivery channel).
- No Database, Queue, Redis, or Worker introduced.
- No change to the AI Workspace V1 Baseline or Manual Gate principles.
- No change to `check`, `consensus`, `finalize`, `validate-final-consensus`, or canonical artifact naming rules.
- No automatic invocation of Claude Code or Codex; no automatic Commit or Push.
- No handling of unrelated dirty/untracked files in the working tree.
- No `git add`, `git commit`, or `git push`.
- `Status`, `Package Version`, and `Validation Support` (Sprint-012 draft fields) were intentionally not reintroduced — see Must Fix 4 above.

## Remaining Issues

None blocking. Two non-blocking items noted by `codex_final_review.md` (Nit 2) and carried over here for visibility:

- `reviews/sprint-013/round-001/architecture.md` still contains the pre-Must-Fix term `target_actor` / `Target Actor` in its original (frozen) text, since this report and the Must Fix round intentionally did not rewrite the Architecture artifact itself. The specification and implementation are now corrected; reconciling the Architecture artifact's wording is left to Product Owner's discretion in a future governance action, not performed here to avoid rewriting an already-recorded Architecture decision.
- No automated test independently exercises a real Telegram Bot API call (all Telegram-facing tests use a stub `curl`); real end-to-end delivery still requires Product Owner validation with real `TELEGRAM_BOT_TOKEN` / `TELEGRAM_CHAT_ID` credentials.
