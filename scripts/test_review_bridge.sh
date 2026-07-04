#!/usr/bin/env bash
# test_review_bridge.sh — Regression tests for review_bridge.sh
#
# Run from the repo root:
#   bash scripts/test_review_bridge.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BRIDGE="$SCRIPT_DIR/review_bridge.sh"
TEST_DIR="$(mktemp -d)"
CLEANUP_DONE=false

cleanup() {
  if [[ "$CLEANUP_DONE" == "false" ]]; then
    rm -rf "$TEST_DIR"
    CLEANUP_DONE=true
  fi
}
trap cleanup EXIT

# Override REVIEWS_DIR to use test directory
export REVIEWS_OVERRIDE="$TEST_DIR"

pass_count=0
fail_count=0

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    echo "  PASS: $desc"
    ((pass_count++))
  else
    echo "  FAIL: $desc"
    echo "    expected: $expected"
    echo "    actual:   $actual"
    ((fail_count++))
  fi
}

assert_contains() {
  local desc="$1" needle="$2" haystack="$3"
  if [[ "$haystack" == *"$needle"* ]]; then
    echo "  PASS: $desc"
    ((pass_count++))
  else
    echo "  FAIL: $desc"
    echo "    expected to contain: $needle"
    echo "    actual: $haystack"
    ((fail_count++))
  fi
}

assert_exit_code() {
  local desc="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    echo "  PASS: $desc"
    ((pass_count++))
  else
    echo "  FAIL: $desc (expected exit=$expected, got exit=$actual)"
    ((fail_count++))
  fi
}

###############################################################################
# Test 1: init creates sprint dir and metadata
###############################################################################
echo "=== Test 1: init ==="
output=$(cd "$SCRIPT_DIR" && REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" init test-init 2>&1)
ec=$?
assert_exit_code "init exits 0" 0 "$ec"
assert_contains "creates sprint dir" "test-init" "$output" || true
[[ -d "$TEST_DIR/test-init" ]] && echo "  PASS: sprint dir exists" && ((pass_count++)) || ((fail_count++))
[[ -f "$TEST_DIR/test-init/sprint_meta.env" ]] && echo "  PASS: sprint_meta.env exists" && ((pass_count++)) || ((fail_count++))

###############################################################################
# Test 2: init with round creates round dir
###############################################################################
echo ""
echo "=== Test 2: init with round ==="
cd "$SCRIPT_DIR" && REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" init test-init 002 2>&1
ec=$?
assert_exit_code "init round exits 0" 0 "$ec"
[[ -d "$TEST_DIR/test-init/round-002" ]] && echo "  PASS: round-002 exists" && ((pass_count++)) || ((fail_count++))

###############################################################################
# Test 3: init with existing round fails
###############################################################################
echo ""
echo "=== Test 3: init existing round ==="
output=$(cd "$SCRIPT_DIR" && REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" init test-init 002 2>&1)
ec=$?
assert_exit_code "init existing round fails" 1 "$ec"
assert_contains "error mentions existing" "exists" "$output"

###############################################################################
# Test 4: skeleton creates input artifacts only
###############################################################################
echo ""
echo "=== Test 4: skeleton implementation ==="
cd "$SCRIPT_DIR" && REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" skeleton test-init 001 --type implementation 2>&1
ec=$?
assert_exit_code "skeleton exits 0" 0 "$ec"
for f in architecture.md claude_report.md codex_prompt.md codex_review.md claude_reply.md codex_final_review.md; do
  [[ -f "$TEST_DIR/test-init/round-001/$f" ]] && echo "  PASS: $f exists" && ((pass_count++)) || ((fail_count++))
done
# Gate artifacts must NOT exist
[[ ! -f "$TEST_DIR/test-init/round-001/consensus_report.md" ]] && echo "  PASS: consensus_report.md NOT created" && ((pass_count++)) || ((fail_count++))
[[ ! -f "$TEST_DIR/test-init/round-001/final_consensus.md" ]] && echo "  PASS: final_consensus.md NOT created" && ((pass_count++)) || ((fail_count++))

###############################################################################
# Test 5: skeleton documentation
###############################################################################
echo ""
echo "=== Test 5: skeleton documentation ==="
cd "$SCRIPT_DIR" && REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" init test-doc 001 2>&1
cd "$SCRIPT_DIR" && REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" skeleton test-doc 001 --type documentation 2>&1
[[ -f "$TEST_DIR/test-doc/round-001/reviewed_document.md" ]] && echo "  PASS: reviewed_document.md exists" && ((pass_count++)) || ((fail_count++))
[[ ! -f "$TEST_DIR/test-doc/round-001/architecture.md" ]] && echo "  PASS: architecture.md NOT created for doc sprint" && ((pass_count++)) || ((fail_count++))

###############################################################################
# Test 6: check — missing artifacts
###############################################################################
echo ""
echo "=== Test 6: check missing ==="
rm -rf "$TEST_DIR/test-check"
cd "$SCRIPT_DIR" && REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" init test-check 001 2>&1
cd "$SCRIPT_DIR" && REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" skeleton test-check 001 --type implementation 2>&1
rm "$TEST_DIR/test-check/round-001/codex_review.md"
output=$(cd "$SCRIPT_DIR" && REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" check test-check 001 2>&1)
ec=$?
assert_exit_code "check missing exits 1" 1 "$ec"
assert_contains "check missing shows MISSING" "MISSING" "$output"

###############################################################################
# Test 7: check — placeholder detection
###############################################################################
echo ""
echo "=== Test 7: check placeholder ==="
rm -rf "$TEST_DIR/test-placeholder"
cd "$SCRIPT_DIR" && REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" init test-placeholder 001 2>&1
cd "$SCRIPT_DIR" && REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" skeleton test-placeholder 001 --type implementation 2>&1
output=$(cd "$SCRIPT_DIR" && REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" check test-placeholder 001 2>&1)
ec=$?
# Placeholder should warn but not fail (exit 0) with PLACEHOLDER marker
assert_contains "check shows PLACEHOLDER" "PLACEHOLDER" "$output"
assert_contains "check warns about placeholders" "placeholder" "$output"

###############################################################################
# Test 8: check — all ready
###############################################################################
echo ""
echo "=== Test 8: check all ready ==="
rm -rf "$TEST_DIR/test-ready"
cd "$SCRIPT_DIR" && REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" init test-ready 001 2>&1
cd "$SCRIPT_DIR" && REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" skeleton test-ready 001 --type implementation 2>&1
# Replace placeholder content with real content
for f in architecture.md claude_report.md codex_prompt.md codex_review.md claude_reply.md codex_final_review.md; do
  echo "# Real content for $f" > "$TEST_DIR/test-ready/round-001/$f"
done
output=$(cd "$SCRIPT_DIR" && REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" check test-ready 001 2>&1)
ec=$?
assert_exit_code "check ready exits 0" 0 "$ec"
assert_contains "check shows READY" "READY" "$output"
assert_contains "check shows PASS" "PASS" "$output"

###############################################################################
# Test 9: consensus — placeholders cause FAIL
###############################################################################
echo ""
echo "=== Test 9: consensus with placeholders ==="
rm -rf "$TEST_DIR/test-pl-consensus"
cd "$SCRIPT_DIR" && REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" init test-pl-consensus 001 2>&1
cd "$SCRIPT_DIR" && REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" skeleton test-pl-consensus 001 --type implementation 2>&1
output=$(cd "$SCRIPT_DIR" && REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" consensus test-pl-consensus 001 2>&1)
ec=$?
assert_exit_code "consensus with placeholders exits 0 (report written)" 0 "$ec"
assert_contains "consensus FAIL on placeholders" "Gate Status: FAIL" "$output"
assert_contains "consensus mentions placeholders" "Placeholder" "$output"

###############################################################################
# Test 10: consensus — all markers PASS
###############################################################################
echo ""
echo "=== Test 10: consensus all PASS ==="
rm -rf "$TEST_DIR/test-pass"
cd "$SCRIPT_DIR" && REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" init test-pass 001 2>&1
cd "$SCRIPT_DIR" && REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" skeleton test-pass 001 --type implementation 2>&1
# Write real content with proper markers
cat > "$TEST_DIR/test-pass/round-001/codex_review.md" <<'M'
Must Fix: None
Architecture Conflict: None
Final Recommendation: PASS
M
cat > "$TEST_DIR/test-pass/round-001/claude_reply.md" <<'M'
Must Fix Addressed: Yes
Architecture Conflict Addressed: Yes
Final Recommendation: PASS
M
cat > "$TEST_DIR/test-pass/round-001/codex_final_review.md" <<'M'
Final Recommendation: PASS
M
cat > "$TEST_DIR/test-pass/round-001/claude_report.md" <<'M'
Scope Expansion: No
M
# Real content for non-marker files
echo "# Architecture" > "$TEST_DIR/test-pass/round-001/architecture.md"
echo "# Prompt" > "$TEST_DIR/test-pass/round-001/codex_prompt.md"
output=$(cd "$SCRIPT_DIR" && REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" consensus test-pass 001 2>&1)
ec=$?
assert_exit_code "consensus PASS exits 0" 0 "$ec"
assert_contains "consensus Gate PASS" "Gate Status: PASS" "$output"

###############################################################################
# Test 11: finalize — only when Gate PASS
###############################################################################
echo ""
echo "=== Test 11: finalize gate ==="
output=$(cd "$SCRIPT_DIR" && REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" finalize test-pass 001 2>&1)
ec=$?
assert_exit_code "finalize when PASS exits 0" 0 "$ec"
assert_contains "final_consensus.md created" "Written:" "$output"
[[ -f "$TEST_DIR/test-pass/round-001/final_consensus.md" ]] && echo "  PASS: final_consensus.md exists" && ((pass_count++)) || ((fail_count++))

###############################################################################
# Test 12: finalize — marker summary in final_consensus
###############################################################################
echo ""
echo "=== Test 12: finalize marker summary ==="
fc_content=$(cat "$TEST_DIR/test-pass/round-001/final_consensus.md")
assert_contains "final_consensus has Must Fix" "Must Fix:" "$fc_content"
assert_contains "final_consensus has Scope Expansion" "Scope Expansion:" "$fc_content"
assert_contains "final_consensus has Sprint Type" "Sprint Type: implementation" "$fc_content"

###############################################################################
# Test 13: validate-final-consensus — correct placement
###############################################################################
echo ""
echo "=== Test 13: validate placement ==="
output=$(cd "$SCRIPT_DIR" && REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" validate-final-consensus test-pass 2>&1)
ec=$?
assert_exit_code "validate correct exits 0" 0 "$ec"
assert_contains "validate PASS" "PASS" "$output"

###############################################################################
# Test 14: path traversal protection
###############################################################################
echo ""
echo "=== Test 14: path traversal ==="
for bad_id in "../etc" "sprint/004" "..foo" "foo bar"; do
  output=$(cd "$SCRIPT_DIR" && REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" init "$bad_id" 2>&1) || true
  assert_contains "rejects $bad_id" "Invalid" "$output"
done

###############################################################################
# Test 15: dry-run does not write
###############################################################################
echo ""
echo "=== Test 15: dry-run ==="
output=$(cd "$SCRIPT_DIR" && REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" skeleton test-pass 002 --type documentation --dry-run 2>&1)
assert_contains "dry-run shows would" "Would" "$output"
[[ ! -d "$TEST_DIR/test-pass/round-002" ]] && echo "  PASS: dry-run did not create round-002" && ((pass_count++)) || ((fail_count++))

###############################################################################
# Test 16: codex_prompt.md placeholder does not block check / consensus
###############################################################################
echo ""
echo "=== Test 16: codex_prompt.md placeholder is non-blocking ==="
rm -rf "$TEST_DIR/test-prompt-exempt"
cd "$SCRIPT_DIR" && REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" init test-prompt-exempt 001 2>&1
cd "$SCRIPT_DIR" && REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" skeleton test-prompt-exempt 001 --type implementation 2>&1
# Fill every artifact EXCEPT codex_prompt.md with real content and PASS-worthy markers.
echo "# Architecture" > "$TEST_DIR/test-prompt-exempt/round-001/architecture.md"
cat > "$TEST_DIR/test-prompt-exempt/round-001/codex_review.md" <<'M'
Must Fix: None
Architecture Conflict: None
Final Recommendation: PASS
M
cat > "$TEST_DIR/test-prompt-exempt/round-001/claude_reply.md" <<'M'
Must Fix Addressed: Yes
Architecture Conflict Addressed: Yes
Final Recommendation: PASS
M
cat > "$TEST_DIR/test-prompt-exempt/round-001/codex_final_review.md" <<'M'
Final Recommendation: PASS
M
cat > "$TEST_DIR/test-prompt-exempt/round-001/claude_report.md" <<'M'
Scope Expansion: No
M
# codex_prompt.md is intentionally left as the skeleton placeholder.

check_out=$(cd "$SCRIPT_DIR" && REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" check test-prompt-exempt 001 2>&1)
check_ec=$?
assert_exit_code "check exits 0 when only codex_prompt.md is placeholder" 0 "$check_ec"
assert_contains "check still reports codex_prompt.md as PLACEHOLDER" "codex_prompt.md: PLACEHOLDER" "$check_out"
assert_contains "check reports overall PASS (non-blocking)" "PASS:" "$check_out"

cons_out=$(cd "$SCRIPT_DIR" && REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" consensus test-prompt-exempt 001 2>&1)
assert_contains "consensus PASS despite codex_prompt.md placeholder" "Gate Status: PASS" "$cons_out"

###############################################################################
# Test 17: codex_prompt.md missing still blocks (existence check unaffected)
###############################################################################
echo ""
echo "=== Test 17: codex_prompt.md missing still fails check ==="
rm "$TEST_DIR/test-prompt-exempt/round-001/codex_prompt.md"
output=$(cd "$SCRIPT_DIR" && REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" check test-prompt-exempt 001 2>&1)
ec=$?
assert_exit_code "check fails when codex_prompt.md is missing" 1 "$ec"
assert_contains "check reports codex_prompt.md as MISSING" "codex_prompt.md: MISSING" "$output"

###############################################################################
# Test 18: n8n webhook notification (optional, best-effort, non-blocking)
###############################################################################
echo ""
echo "=== Test 18: n8n webhook notification ==="
rm -rf "$TEST_DIR/test-webhook"
cd "$SCRIPT_DIR" && REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" init test-webhook 001 2>&1
cd "$SCRIPT_DIR" && REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" skeleton test-webhook 001 --type implementation 2>&1
for f in architecture.md claude_report.md codex_prompt.md codex_review.md claude_reply.md codex_final_review.md; do
  echo "# Real content for $f" > "$TEST_DIR/test-webhook/round-001/$f"
done

# 18a: env var unset -> behavior identical to before this feature existed.
output=$(cd "$SCRIPT_DIR" && env -u N8N_CLAUDE_DONE_WEBHOOK_URL REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" check test-webhook 001 2>&1)
ec=$?
assert_exit_code "check exits 0 without webhook env var" 0 "$ec"
assert_contains "check still reports PASS without webhook env var" "PASS:" "$output"
if [[ "$output" != *"N8N_CLAUDE_DONE_WEBHOOK_URL"* && "$output" != *"WARNING"* ]]; then
  echo "  PASS: no webhook attempt/warning when env var unset"
  ((pass_count++))
else
  echo "  FAIL: unexpected webhook mention when env var unset"
  ((fail_count++))
fi

# 18b: env var set to an unreachable URL -> curl fails, only a WARNING is
# printed, exit code and PASS status are unaffected.
output=$(cd "$SCRIPT_DIR" && REVIEWS_OVERRIDE="$TEST_DIR" N8N_CLAUDE_DONE_WEBHOOK_URL="http://127.0.0.1:1/webhook" bash "$BRIDGE" check test-webhook 001 2>&1)
ec=$?
assert_exit_code "check still exits 0 when webhook POST fails" 0 "$ec"
assert_contains "check still reports PASS when webhook POST fails" "PASS:" "$output"
assert_contains "check prints WARNING when webhook POST fails" "WARNING: Failed to POST claude_report.md notification" "$output"

# 18c: --dry-run with webhook set -> shows a dry-run message and does not
# attempt any real POST (no WARNING, since curl is never invoked).
output=$(cd "$SCRIPT_DIR" && REVIEWS_OVERRIDE="$TEST_DIR" N8N_CLAUDE_DONE_WEBHOOK_URL="http://127.0.0.1:1/webhook" bash "$BRIDGE" check test-webhook 001 --dry-run 2>&1)
assert_contains "dry-run shows would-POST message" "[dry-run] Would POST claude_report.md notification" "$output"
if [[ "$output" != *"WARNING: Failed to POST"* ]]; then
  echo "  PASS: dry-run does not attempt actual POST"
  ((pass_count++))
else
  echo "  FAIL: dry-run unexpectedly attempted POST"
  ((fail_count++))
fi

###############################################################################
# Test 19: n8n codex review webhook notification (optional, best-effort)
###############################################################################
echo ""
echo "=== Test 19: n8n codex review webhook notification ==="
rm -rf "$TEST_DIR/test-codex-webhook"
cd "$SCRIPT_DIR" && REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" init test-codex-webhook 001 2>&1
cd "$SCRIPT_DIR" && REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" skeleton test-codex-webhook 001 --type implementation 2>&1
for f in architecture.md claude_report.md codex_prompt.md codex_review.md claude_reply.md codex_final_review.md; do
  echo "# Real content for $f" > "$TEST_DIR/test-codex-webhook/round-001/$f"
done

# 19a: env var unset -> behavior identical to before this feature existed.
output=$(cd "$SCRIPT_DIR" && env -u N8N_CODEX_REVIEW_DONE_WEBHOOK_URL REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" check test-codex-webhook 001 2>&1)
ec=$?
assert_exit_code "check exits 0 without codex webhook env var" 0 "$ec"
assert_contains "check still reports PASS without codex webhook env var" "PASS:" "$output"
if [[ "$output" != *"N8N_CODEX_REVIEW_DONE_WEBHOOK_URL"* && "$output" != *"WARNING"* ]]; then
  echo "  PASS: no codex webhook attempt/warning when env var unset"
  ((pass_count++))
else
  echo "  FAIL: unexpected codex webhook mention when env var unset"
  ((fail_count++))
fi

# 19b: env var set to an unreachable URL -> both codex_review.md and
# codex_final_review.md are READY, so both notifications are attempted and
# both fail -> two WARNINGs, exit code and PASS status unaffected, and the
# webhook URL itself is never printed.
output=$(cd "$SCRIPT_DIR" && REVIEWS_OVERRIDE="$TEST_DIR" N8N_CODEX_REVIEW_DONE_WEBHOOK_URL="http://127.0.0.1:1/webhook" bash "$BRIDGE" check test-codex-webhook 001 2>&1)
ec=$?
assert_exit_code "check still exits 0 when codex webhook POST fails" 0 "$ec"
assert_contains "check still reports PASS when codex webhook POST fails" "PASS:" "$output"
assert_contains "check warns for codex_review failure" "WARNING: Failed to POST codex_review notification to N8N webhook" "$output"
assert_contains "check warns for codex_final_review failure" "WARNING: Failed to POST codex_final_review notification to N8N webhook" "$output"
if [[ "$output" != *"127.0.0.1:1"* ]]; then
  echo "  PASS: warning does not leak the webhook URL"
  ((pass_count++))
else
  echo "  FAIL: warning leaked the webhook URL"
  ((fail_count++))
fi

# 19c: --dry-run with codex webhook set -> shows would-POST messages for both
# review_type values, no real POST attempted.
output=$(cd "$SCRIPT_DIR" && REVIEWS_OVERRIDE="$TEST_DIR" N8N_CODEX_REVIEW_DONE_WEBHOOK_URL="http://127.0.0.1:1/webhook" bash "$BRIDGE" check test-codex-webhook 001 --dry-run 2>&1)
assert_contains "dry-run shows would-POST for codex_review" "[dry-run] Would POST codex_review notification" "$output"
assert_contains "dry-run shows would-POST for codex_final_review" "[dry-run] Would POST codex_final_review notification" "$output"
if [[ "$output" != *"WARNING: Failed to POST"* ]]; then
  echo "  PASS: dry-run does not attempt actual codex webhook POST"
  ((pass_count++))
else
  echo "  FAIL: dry-run unexpectedly attempted codex webhook POST"
  ((fail_count++))
fi

# 19d: the two webhook env vars are independent — setting only
# N8N_CLAUDE_DONE_WEBHOOK_URL must not trigger any codex review notification.
output=$(cd "$SCRIPT_DIR" && env -u N8N_CODEX_REVIEW_DONE_WEBHOOK_URL REVIEWS_OVERRIDE="$TEST_DIR" N8N_CLAUDE_DONE_WEBHOOK_URL="http://127.0.0.1:1/webhook" bash "$BRIDGE" check test-codex-webhook 001 2>&1)
assert_contains "only claude_report.md warning appears when only claude webhook is set" "WARNING: Failed to POST claude_report.md notification" "$output"
if [[ "$output" != *"codex_review notification"* && "$output" != *"codex_final_review notification"* ]]; then
  echo "  PASS: codex webhook not triggered when only claude webhook env var is set"
  ((pass_count++))
else
  echo "  FAIL: codex webhook unexpectedly triggered"
  ((fail_count++))
fi

###############################################################################
# Sprint-004 E2E compatibility
###############################################################################
echo ""
echo "=== Sprint-004 E2E Compatibility ==="
rm -rf "$TEST_DIR/sprint-004-e2e"
cd "$SCRIPT_DIR" && REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" init sprint-004-e2e 001 2>&1
cd "$SCRIPT_DIR" && REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" skeleton sprint-004-e2e 001 --type implementation 2>&1
# Write proper markers
for f in codex_review.md claude_reply.md codex_final_review.md claude_report.md; do
  echo "# Real content" > "$TEST_DIR/sprint-004-e2e/round-001/$f"
done
echo "# Architecture" > "$TEST_DIR/sprint-004-e2e/round-001/architecture.md"
echo "# Prompt" > "$TEST_DIR/sprint-004-e2e/round-001/codex_prompt.md"
cat > "$TEST_DIR/sprint-004-e2e/round-001/codex_review.md" <<'M'
Must Fix: None
Architecture Conflict: None
Final Recommendation: PASS
M
cat > "$TEST_DIR/sprint-004-e2e/round-001/claude_reply.md" <<'M'
Must Fix Addressed: Yes
Architecture Conflict Addressed: Yes
Final Recommendation: PASS
M
cat > "$TEST_DIR/sprint-004-e2e/round-001/codex_final_review.md" <<'M'
Final Recommendation: PASS
M
cat > "$TEST_DIR/sprint-004-e2e/round-001/claude_report.md" <<'M'
Scope Expansion: No
M

# Full E2E flow
check_out=$(cd "$SCRIPT_DIR" && REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" check sprint-004-e2e 001 2>&1)
cons_out=$(cd "$SCRIPT_DIR" && REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" consensus sprint-004-e2e 001 2>&1)
fin_out=$(cd "$SCRIPT_DIR" && REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" finalize sprint-004-e2e 001 2>&1)
val_out=$(cd "$SCRIPT_DIR" && REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" validate-final-consensus sprint-004-e2e 2>&1)

assert_contains "E2E check PASS" "PASS" "$check_out"
assert_contains "E2E consensus Gate PASS" "Gate Status: PASS" "$cons_out"
assert_contains "E2E finalize succeeds" "Written:" "$fin_out"
assert_contains "E2E validate PASS" "PASS" "$val_out"
[[ -f "$TEST_DIR/sprint-004-e2e/round-001/final_consensus.md" ]] && echo "  PASS: E2E final_consensus.md exists" && ((pass_count++)) || ((fail_count++))

###############################################################################
# Summary
###############################################################################
echo ""
echo "================================"
echo "Results: $pass_count passed, $fail_count failed"
echo "================================"

if [[ $fail_count -gt 0 ]]; then
  exit 1
fi
exit 0
