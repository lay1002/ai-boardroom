# Codex Review - Sprint-016

## Summary

FAIL

Sprint-016 is within the intended file scope and tests pass, but two Architecture-level requirements are not fully satisfied:

1. `docs/development/product-owner-gate-metadata.md` claims to canonicalize the runtime metadata from `_gate_resolve_metadata()`, including `current_status_zh`, but the per-Gate canonical metadata does not actually record each Gate's `current_status_zh`.
2. `_gate_validate_metadata()` does not validate `recommended_execution_mode`, even though Sprint-016 Architecture explicitly requires validation hardening for `recommended_execution_mode`.

These are Must Fix items because the Sprint goal is metadata canonicalization and validation hardening.

## Scope Review

- Allowed files only: PASS
- Prohibited files untouched: PASS
- No unrelated dirty / untracked files included: PASS

Evidence:

- Sprint-016 implementation changes are limited to the allowed files:
  - `docs/development/product-owner-gate-metadata.md`
  - `docs/development/telegram-po-gate-notification-specification.md`
  - `docs/development/execution-permission-policy.md`
  - `scripts/review_bridge.sh`
  - `scripts/test_review_bridge.sh`
  - `reviews/sprint-016/round-001/architecture.md`
  - `reviews/sprint-016/round-001/claude_report.md`
- `git diff --cached --name-only` is empty; no staging was performed.
- Focused status check for prohibited paths shows only pre-existing runtime evidence:

```text
?? reviews/notification_history.jsonl
?? reviews/sprint-013/round-001/notifications/
```

- `configs/n8n/`, `reviews/sprint-014/round-001/notifications/`, and `reviews/sprint-015/round-001/dirty-files-inventory.md` show no pending Sprint-016 modification.
- Existing unrelated dirty/untracked files remain in the working tree, but are not staged and are not part of Sprint-016 implementation scope.

## Architecture / Metadata Review

- 21 Gate metadata canonical source: FAIL
- Required fields complete: FAIL
- Runtime metadata alignment: FAIL
- Telegram PO Gate Notification Specification alignment: PASS with dependency on Must Fix 1
- Execution Permission Policy alignment: PASS

Evidence:

- `docs/development/product-owner-gate-metadata.md` exists and lists all 21 gate IDs.
- The document defines 14 required canonical fields and clearly distinguishes command-level Safety Level from Gate approval.
- The document states that `_gate_resolve_metadata()` populated `gate_name_zh`, `next_actor`, `recommended_execution_mode`, `risk_level`, `current_status_zh`, and `product_owner_next_action_zh`, and says Sprint-016 canonicalizes these values.
- However, the per-Gate canonical metadata does not include each Gate's `current_status_zh` value, while runtime still contains `GATE_STATUS_ZH` for all 21 Gates.
- Because `telegram-po-gate-notification-specification.md` now points Product Owner to `product-owner-gate-metadata.md` as the canonical source for the 21 Gate metadata, the missing `current_status_zh` makes the canonical artifact incomplete relative to runtime.
- `execution-permission-policy.md` correctly adds Safety Level 0-3 and explicitly states Safety Level classifies tool invocations, not Product Owner Gate approvals.
- Commit / Push / high-risk Gates remain Level 3 / Manual Gate required. Level 0 is limited to read-only sandbox-safe operations and does not authorize Gate approval.

## Runtime / Validation Review

- `_gate_validate_metadata` defensive validation only: FAIL
- Telegram delivery behavior unchanged: PASS
- n8n JSON untouched: PASS
- AI Auto Loop not introduced: PASS

Evidence:

- `_gate_validate_metadata()` validates:
  - `GATE_NEXT_ACTOR` enum.
  - `GATE_RISK_LEVEL` enum.
  - high-risk Gate requires `risk_level=high`.
  - non-empty `GATE_NAME_ZH`, `GATE_STATUS_ZH`, and `GATE_PO_ACTION_ZH`.
- It does not validate `GATE_EXEC_MODE` / `recommended_execution_mode` against the allowed mode list.
- Sprint-016 Architecture explicitly required validation hardening for `gate_id/next_actor/recommended_execution_mode/risk_level`.
- Telegram delivery behavior appears unchanged:
  - `_notify_split_for_telegram` is not changed.
  - Telegram curl send path is not changed.
  - `NOTIFICATION_ENABLED`, `TELEGRAM_BOT_TOKEN`, and `TELEGRAM_CHAT_ID` checks are not changed.
  - Changes are limited to metadata validation and package wording.
- No n8n JSON changes were found.
- No AI Auto Loop, automatic Claude/Codex invocation, automatic commit, or automatic push behavior was introduced.

## Test Review

- Test command:

```bash
bash scripts/test_review_bridge.sh
```

- Result:

```text
Results: 188 passed, 0 failed
```

- Notes:
  - Direct execution with `./scripts/test_review_bridge.sh` failed due file execute permission, so the existing project test invocation was run through `bash`.
  - Test 25 verifies all runtime Gate IDs are mentioned in the canonical doc, but it does not verify that every required per-Gate canonical field is present.
  - Test 25 says it covers `recommended_execution_mode`, but the runtime validator currently does not enforce the `GATE_EXEC_MODE` allowed values.

## Must Fix

1. Add each Gate's `current_status_zh` to `docs/development/product-owner-gate-metadata.md`, or otherwise adjust the canonical field contract so it no longer claims full alignment with runtime `GATE_STATUS_ZH`. The preferred fix is to include `current_status_zh`, because Telegram Gate messages use it and runtime already treats it as required metadata.
2. Update `_gate_validate_metadata()` to validate `GATE_EXEC_MODE` / `recommended_execution_mode` against the allowed values defined by `execution-permission-policy.md` / `telegram-po-gate-notification-specification.md`, including the approved `N/A（...）` decision-point values.
3. Extend Test 25 so it would fail if the canonical metadata omits required per-Gate fields such as `current_status_zh`, or if `recommended_execution_mode` validation is missing.

## Should Fix

- None.

## Nit

- Consider documenting that `bash scripts/test_review_bridge.sh` is the canonical test invocation if the script is intentionally not executable.

## Final Recommendation

REQUEST_CHANGES
