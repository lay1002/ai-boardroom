# Codex Review - Sprint-013

## Summary

FAIL

Implementation is close at the runtime level: `notify` is additive, the event whitelist in code matches Sprint-013 Architecture, tests pass, no Database / Queue / Worker / AI Auto Loop was introduced, and Telegram secret handling is generally safe.

However, the implementation does not yet satisfy the approved Notification Package / Manual Gate architecture because the delivered Telegram message is not the Notification Package artifact itself, `target_actor` can be confused with notification recipient, and the Notification Package Specification SSOT now explicitly contains an unresolved event-model discrepancy.

## Scope Review

The implementation stays within the intended Sprint-013 runtime scope:

- Added `scripts/review_bridge.sh notify`.
- Generates Notification Package files under `reviews/<sprint-id>/round-<round>/notifications/<event_type>.md`.
- Uses `reviews/notification_history.jsonl` for append-only delivery history.
- Implements deduplication by project / sprint / round / event / artifact path / artifact hash.
- Uses direct Telegram Bot API delivery.
- Does not introduce Database, Queue, Redis, Worker, Web UI, Notification Center, Slack / LINE / Email delivery, AI Auto Loop, automatic Claude / Codex invocation, automatic Commit, or automatic Push.

The working tree still contains unrelated dirty / untracked files outside Sprint-013. They were not modified or staged by this review.

## Architecture Compliance

Partial compliance.

Compliant:

- `notify` is additive and does not alter existing `check`, `consensus`, `finalize`, or `validate-final-consensus` dispatch paths.
- The accepted Sprint-013 event whitelist is implemented exactly:
  - `claude_implementation_done`
  - `codex_review_done`
  - `claude_should_fix_done`
  - `codex_final_review_done`
  - `git_review_done`
  - `commit_done`
  - `push_done`
  - `retrospective_done`
- Generic project / sprint / round support is present via `PROJECT_ID`, `PROJECT_NAME`, CLI `sprint_id`, and CLI `round`.
- Existing n8n webhook hooks remain intact.
- Manual Gate is not bypassed.

Not compliant:

- Sprint-013 Architecture says the Notification Package is the sole content source for Telegram delivery and the Telegram adapter must send the package text unmodified. The implementation writes `notif_path`, but then builds a separate `message_text` from variables and sends that to Telegram. This is a separate rendering path and can drift from the artifact.
- `docs/development/notification-package-specification.md` remains the Notification Package SSOT, but its Section 2 event model and Section 3 field contract do not match the Sprint-013 runtime. The added Sprint-013 note records a "Known discrepancy" instead of resolving the SSOT conflict.
- The generated package does not satisfy the existing SSOT's exact 14-field contract: it lacks fields such as `Status`, `Created Time`, `Package Version`, `Summary`, `Next Step`, `Validation Support`, `Artifact Path`, and `Delivery Status` in the SSOT-defined form.

## Implementation Review

`notify` command:

- Correctly validates `sprint_id` and `round`.
- Rejects invalid event types before delivery.
- Requires `PROJECT_ID` and `PROJECT_NAME`, avoiding hardcoded project identity.
- Rejects artifact paths containing `..`.
- Writes package artifacts to the expected notification directory.

Deduplication:

- Deduplication key format matches Sprint-013 Architecture:
  `<project_id>/<sprint_id>/<round_id>/<event_type>/<artifact_path>/<artifact_hash>`.
- Existing `delivered` records block duplicate delivery.
- Changed artifact content produces a new hash and permits a new delivery.
- `failed` and `disabled` do not block retries.
- `skipped_duplicate` exits successfully, which is appropriate.

Notification History:

- Uses append-only JSON Lines.
- Records required Sprint-013 history fields.
- Uses allowed lower-case delivery statuses from Sprint-013 Architecture.

Telegram Adapter:

- Delivery is opt-in via `NOTIFICATION_ENABLED=true`.
- Missing token / chat ID records `disabled`.
- Telegram API failure records `failed` and preserves the package.
- Delivery failure exits 0, which is acceptable for this Sprint because notification is best-effort and must not block the Manual Gate workflow.

Blocking issue: Telegram does not send the package artifact unmodified. It sends a separately composed `message_text`.

## Security Review

PASS with one implementation caveat.

- No Telegram bot token or chat ID is hardcoded.
- Token and chat ID are read from environment variables.
- Tests verify `TELEGRAM_BOT_TOKEN` does not appear in stdout / stderr, package, or history.
- Warnings do not print the Telegram URL.
- `NOTIFICATION_ENABLED` must be exactly `true` before any Telegram send is attempted.

Caveat: the command permits absolute artifact paths. This is not shown to leak secrets by itself, but a future hardening pass should prefer repo-relative artifacts unless Product Owner explicitly approves cross-repo paths.

## Manual Gate Review

FAIL.

The implementation does not auto-approve, auto-call Claude, auto-call Codex, auto-commit, auto-push, or advance workflow state. That part preserves Manual Gate.

The issue is semantic: for events such as `claude_implementation_done`, the generated package says `Target Actor: Codex` and the `Next Product Owner Action` section says "Codex should review...". Since Sprint-013's purpose is to notify Product Owner before Manual Gate, the package should clearly distinguish:

- `notification_recipient`: Product Owner
- `next_actor`: Codex / Claude Code / Product Owner
- `next_product_owner_action`: e.g. "Product Owner should copy the handoff package to Codex and decide whether to proceed."

Without this separation, the Telegram recipient and next executor are conflated, and Product Owner may receive a notification that appears addressed to another actor.

## Test Review

Executed:

```bash
bash scripts/test_review_bridge.sh
```

Result:

```text
128 passed, 0 failed
```

Coverage confirmed:

- Existing Review Bridge behavior remains covered.
- n8n webhook behavior remains covered.
- Handoff Package behavior remains covered.
- `notify` package generation is covered.
- Duplicate prevention is covered.
- Changed artifact hash is covered.
- Missing artifact is covered.
- Missing Telegram config is covered.
- Invalid event type is covered.
- Generic sprint / round / project identity is covered.
- Telegram token non-leak is covered.
- No git commit / git push / Claude / Codex API invocation is checked.

Coverage gaps:

- No test verifies Telegram sends the exact Notification Package artifact content unmodified.
- No test verifies the generated package conforms to the SSOT 14-field contract.
- No test verifies `notification_recipient` vs `next_actor` separation.
- `--dry-run` does not write package/history, so there is no test for the Architecture statement that dry-run maps to `delivery_status=pending`.

## Risk Review

- `target_actor` confusion: Blocking. Current implementation uses `target_actor` as the next executor, while Telegram delivery is intended for Product Owner. This should be split into recipient and next actor fields.
- `--dry-run` history: Not blocking by itself, but inconsistent with Sprint-013 Architecture text saying dry-run maps to `delivery_status=pending`. Either implementation or Architecture/spec wording must be reconciled.
- Telegram failure exit 0: Acceptable. The command records `failed`, preserves the package, and does not block the workflow.
- Notification Package Specification modification: Not acceptable as-is. Adding an Implementation Status note is reasonable, but leaving an explicit "Known discrepancy" in the SSOT creates a governance conflict instead of resolving it.

## Git / Repository State Review

Sprint-013 related files observed:

- `scripts/review_bridge.sh`
- `scripts/test_review_bridge.sh`
- `docs/development/notification-package-specification.md`
- `reviews/sprint-013/round-001/architecture.md`
- `reviews/sprint-013/round-001/codex_review.md` (created by this review)

Unrelated dirty / untracked files exist and were not handled:

- `AGENTS.md`
- `CLAUDE.md`
- `CODEX.md`
- `GPT.md`
- `docs/architecture.md`
- `docs/development/n8n-claude-done-notification.md`
- `docs/development/n8n-codex-review-done-notification.md`
- `docs/vision.md`
- `reviews/sprint-004/round-001/architecture.md`
- `reviews/sprint-004/round-001/claude_report.md`
- `reviews/sprint-004/round-001/codex_review.md`
- `docs/principles.md`
- `docs/roadmap.md`
- `reviews/notification-gap-review.md`
- `reviews/sprint-006/`
- `reviews/sprint-007/`
- `reviews/sprint-009/`

Staged files:

None.

No commit or push was performed.

## Must Fix

1. Telegram delivery must send the Notification Package artifact content unmodified. The current separate `message_text` rendering path violates Artifact First / SSOT delivery rules.
2. Separate notification recipient from next actor. Product Owner must be clearly identified as the Telegram recipient / Manual Gate owner, while Codex or Claude Code may be identified separately as `next_actor`.
3. Fix the Notification Package Specification SSOT conflict. The Sprint-013 runtime event whitelist and package contract must not remain in a documented "Known discrepancy" state against Section 2 / Section 3.
4. Align the generated Notification Package with the governing package contract, or update the approved SSOT contract through this Sprint's authorized scope so the runtime artifact is valid by definition.

## Should Fix

1. Reconcile `--dry-run` behavior with Architecture: either dry-run should write a `pending` history record as specified, or the Architecture/spec should explicitly define dry-run as no-write / no-delivery.
2. Add tests that assert Telegram sends the exact package artifact content, not a separately rendered message.
3. Add tests for recipient / next actor separation and package contract compliance.

## Nit

1. The generated package uses `Copyable Handoff Package`, while the existing SSOT uses `Copy & Paste Prompt`. Prefer one canonical label once the SSOT conflict is resolved.
2. Consider using repo-relative artifact paths only unless a future Sprint explicitly approves absolute paths.

## Final Recommendation

FAIL
