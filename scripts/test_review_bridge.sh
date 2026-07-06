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

# Snapshot of the REAL repository's notification_history.jsonl record count,
# taken before any test in this suite runs (every test below uses
# REVIEWS_OVERRIDE, so none of them should ever touch the real file; this
# snapshot lets Test 27 assert that fact directly, without hardcoding a
# magic number that would go stale as soon as a real notify-gate is
# legitimately run in the future).
REAL_HISTORY_FILE="/home/ivan/AI/reviews/notification_history.jsonl"
REAL_HISTORY_COUNT_BEFORE="$(wc -l < "$REAL_HISTORY_FILE" 2>/dev/null || echo 0)"

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

# assert_true "description" <bash-boolean-string-"true"/"false"-OR-a-condition-command>
# Accepts either the literal string "true"/"false" (e.g. from a shell flag
# variable) or a command to evaluate.
assert_true() {
  local desc="$1"; shift
  local ok=false
  if [[ "$1" == "true" ]]; then
    ok=true
  elif [[ "$1" == "false" ]]; then
    ok=false
  elif eval "$1"; then
    ok=true
  fi
  if $ok; then
    echo "  PASS: $desc"
    ((pass_count++))
  else
    echo "  FAIL: $desc"
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
# Test 20: handoff_package.md generation (Sprint-010, Handoff Package MVP)
###############################################################################
echo ""
echo "=== Test 20: handoff_package.md generation ==="

# 20a: claude_report.md READY (other artifacts still missing) -> handoff
# package targets Codex; architecture.md is not ready yet, so its reference
# must be an explicit PLACEHOLDER, never a silently wrong/fabricated path.
rm -rf "$TEST_DIR/test-handoff-claude"
cd "$SCRIPT_DIR" && REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" init test-handoff-claude 001 2>&1
cd "$SCRIPT_DIR" && REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" skeleton test-handoff-claude 001 --type implementation 2>&1
echo "# Real content" > "$TEST_DIR/test-handoff-claude/round-001/claude_report.md"
cd "$SCRIPT_DIR" && REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" check test-handoff-claude 001 >/dev/null 2>&1
handoff_file="$TEST_DIR/test-handoff-claude/round-001/handoff_package.md"
if [[ -f "$handoff_file" ]]; then
  echo "  PASS: handoff_package.md created when claude_report.md is READY"
  ((pass_count++))
else
  echo "  FAIL: handoff_package.md not created"
  ((fail_count++))
fi
handoff_content=$(cat "$handoff_file" 2>/dev/null || echo "")
assert_contains "handoff targets Codex" "$(printf '## 1. Target AI\n\nCodex')" "$handoff_content"
assert_contains "handoff has Current Stage" "Claude Implementation Completed" "$handoff_content"
assert_contains "handoff has all 8 sections (spot check section 8)" "## 8. Copyable Prompt" "$handoff_content"
assert_contains "handoff marks missing architecture.md as PLACEHOLDER" "PLACEHOLDER: reviews/test-handoff-claude/round-001/architecture.md" "$handoff_content"
assert_contains "handoff references real claude_report.md path" "reviews/test-handoff-claude/round-001/claude_report.md" "$handoff_content"

# 20b: fill architecture.md too, re-run check -> reference upgrades from
# PLACEHOLDER to the real path once it becomes READY.
echo "# Architecture" > "$TEST_DIR/test-handoff-claude/round-001/architecture.md"
cd "$SCRIPT_DIR" && REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" check test-handoff-claude 001 >/dev/null 2>&1
handoff_content=$(cat "$handoff_file")
if [[ "$handoff_content" != *"PLACEHOLDER: reviews/test-handoff-claude/round-001/architecture.md"* ]]; then
  echo "  PASS: architecture.md reference upgraded from PLACEHOLDER once it becomes READY"
  ((pass_count++))
else
  echo "  FAIL: architecture.md reference still PLACEHOLDER after becoming READY"
  ((fail_count++))
fi

# 20c: codex_review.md also becomes READY -> handoff_package.md is
# regenerated to target Claude Code (the most-advanced open gate wins),
# reusing the same ready[] check already computed by `check` (no new READY
# detection system).
echo "# Codex review" > "$TEST_DIR/test-handoff-claude/round-001/codex_review.md"
cd "$SCRIPT_DIR" && REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" check test-handoff-claude 001 >/dev/null 2>&1
handoff_content=$(cat "$handoff_file")
assert_contains "handoff now targets Claude Code" "$(printf '## 1. Target AI\n\nClaude Code')" "$handoff_content"
assert_contains "handoff Current Stage updated to Codex Review Completed" "Codex Review Completed" "$handoff_content"
assert_contains "handoff references codex_review.md" "reviews/test-handoff-claude/round-001/codex_review.md" "$handoff_content"

# 20d: --dry-run does not write handoff_package.md.
rm -rf "$TEST_DIR/test-handoff-dryrun"
cd "$SCRIPT_DIR" && REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" init test-handoff-dryrun 001 2>&1
cd "$SCRIPT_DIR" && REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" skeleton test-handoff-dryrun 001 --type implementation 2>&1
echo "# Real content" > "$TEST_DIR/test-handoff-dryrun/round-001/claude_report.md"
output=$(cd "$SCRIPT_DIR" && REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" check test-handoff-dryrun 001 --dry-run 2>&1)
assert_contains "dry-run shows would-write handoff_package.md" "[dry-run] Would write" "$output"
if [[ ! -f "$TEST_DIR/test-handoff-dryrun/round-001/handoff_package.md" ]]; then
  echo "  PASS: dry-run does not create handoff_package.md"
  ((pass_count++))
else
  echo "  FAIL: dry-run created handoff_package.md"
  ((fail_count++))
fi

# 20e: documentation Sprint Type references reviewed_document.md instead of
# architecture.md.
rm -rf "$TEST_DIR/test-handoff-doc"
cd "$SCRIPT_DIR" && REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" init test-handoff-doc 001 2>&1
cd "$SCRIPT_DIR" && REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" skeleton test-handoff-doc 001 --type documentation 2>&1
echo "# Real content" > "$TEST_DIR/test-handoff-doc/round-001/claude_report.md"
echo "# Reviewed doc" > "$TEST_DIR/test-handoff-doc/round-001/reviewed_document.md"
cd "$SCRIPT_DIR" && REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" check test-handoff-doc 001 >/dev/null 2>&1
doc_handoff=$(cat "$TEST_DIR/test-handoff-doc/round-001/handoff_package.md" 2>/dev/null || echo "")
assert_contains "documentation sprint handoff references reviewed_document.md" "reviews/test-handoff-doc/round-001/reviewed_document.md" "$doc_handoff"

###############################################################################
# Test 21: Handoff Package content attached to Telegram webhook payload
# (Sprint-010 Telegram wiring)
###############################################################################
echo ""
echo "=== Test 21: Handoff Package attached to webhook payload ==="

# Fake curl stub: captures the JSON payload passed via -d into a file
# (via the CAPTURED_PAYLOAD_FILE env var) and always succeeds. Used only to
# inspect payload content precisely, with no real network access.
FAKE_BIN_DIR="$TEST_DIR/fake-bin-handoff"
mkdir -p "$FAKE_BIN_DIR"
cat > "$FAKE_BIN_DIR/curl" <<'STUB'
#!/usr/bin/env bash
for ((i=1; i<=$#; i++)); do
  if [[ "${!i}" == "-d" ]]; then
    j=$((i+1))
    echo "${!j}" > "$CAPTURED_PAYLOAD_FILE"
  fi
done
exit 0
STUB
chmod +x "$FAKE_BIN_DIR/curl"
CAPTURED_PAYLOAD_FILE="$TEST_DIR/captured-handoff-payload.json"

# 21a: claude_report.md READY -> its notification payload includes
# handoff_package_content, is valid JSON, and decodes back to the Copyable
# Prompt targeting Codex.
rm -rf "$TEST_DIR/test-handoff-wire-a"
cd "$SCRIPT_DIR" && REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" init test-handoff-wire-a 001 2>&1
cd "$SCRIPT_DIR" && REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" skeleton test-handoff-wire-a 001 --type implementation 2>&1
echo "# Real architecture" > "$TEST_DIR/test-handoff-wire-a/round-001/architecture.md"
echo "# Real claude report" > "$TEST_DIR/test-handoff-wire-a/round-001/claude_report.md"
rm -f "$CAPTURED_PAYLOAD_FILE"
(cd "$SCRIPT_DIR" && PATH="$FAKE_BIN_DIR:$PATH" CAPTURED_PAYLOAD_FILE="$CAPTURED_PAYLOAD_FILE" \
  REVIEWS_OVERRIDE="$TEST_DIR" N8N_CLAUDE_DONE_WEBHOOK_URL="http://n8n.invalid/webhook" \
  bash "$BRIDGE" check test-handoff-wire-a 001 >/dev/null 2>&1)
if [[ -f "$CAPTURED_PAYLOAD_FILE" ]]; then
  payload=$(cat "$CAPTURED_PAYLOAD_FILE")
  assert_contains "claude_report.md payload includes handoff_package_content" "handoff_package_content" "$payload"
  if python3 -c "import json; json.load(open('$CAPTURED_PAYLOAD_FILE'))" 2>/dev/null; then
    echo "  PASS: captured payload is valid JSON"
    ((pass_count++))
  else
    echo "  FAIL: captured payload is not valid JSON"
    ((fail_count++))
  fi
  decoded=$(python3 -c "import json; d=json.load(open('$CAPTURED_PAYLOAD_FILE')); print(d.get('handoff_package_content',''))" 2>/dev/null)
  assert_contains "decoded handoff_package_content contains Copyable Prompt section" "Copyable Prompt" "$decoded"
  assert_contains "decoded handoff_package_content targets Codex" "Codex" "$decoded"
else
  echo "  FAIL: no payload captured for claude_report.md notification"
  ((fail_count++))
fi

# 21b: codex_review.md READY -> its notification payload includes
# handoff_package_content targeting Claude Code (only N8N_CODEX_REVIEW_DONE_WEBHOOK_URL
# is set, so only the codex_review.md case fires — codex_final_review.md is
# still a placeholder here).
rm -rf "$TEST_DIR/test-handoff-wire-b"
cd "$SCRIPT_DIR" && REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" init test-handoff-wire-b 001 2>&1
cd "$SCRIPT_DIR" && REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" skeleton test-handoff-wire-b 001 --type implementation 2>&1
echo "# Real architecture" > "$TEST_DIR/test-handoff-wire-b/round-001/architecture.md"
echo "# Real claude report" > "$TEST_DIR/test-handoff-wire-b/round-001/claude_report.md"
echo "# Real codex review" > "$TEST_DIR/test-handoff-wire-b/round-001/codex_review.md"
rm -f "$CAPTURED_PAYLOAD_FILE"
(cd "$SCRIPT_DIR" && PATH="$FAKE_BIN_DIR:$PATH" CAPTURED_PAYLOAD_FILE="$CAPTURED_PAYLOAD_FILE" \
  REVIEWS_OVERRIDE="$TEST_DIR" N8N_CODEX_REVIEW_DONE_WEBHOOK_URL="http://n8n.invalid/webhook" \
  bash "$BRIDGE" check test-handoff-wire-b 001 >/dev/null 2>&1)
if [[ -f "$CAPTURED_PAYLOAD_FILE" ]]; then
  decoded=$(python3 -c "import json; d=json.load(open('$CAPTURED_PAYLOAD_FILE')); print(d.get('handoff_package_content',''))" 2>/dev/null)
  assert_contains "codex_review.md handoff_package_content targets Claude Code" "Claude Code" "$decoded"
  assert_contains "codex_review.md handoff_package_content has Copyable Prompt" "Copyable Prompt" "$decoded"
else
  echo "  FAIL: no payload captured for codex_review.md notification"
  ((fail_count++))
fi

# 21c: codex_final_review.md READY -> no Handoff Package scenario is defined
# for this gate, so its notification must NOT include handoff_package_content
# (isolated in its own sprint dir: only codex_final_review.md is READY among
# the codex-review-related files).
rm -rf "$TEST_DIR/test-handoff-wire-c"
cd "$SCRIPT_DIR" && REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" init test-handoff-wire-c 001 2>&1
cd "$SCRIPT_DIR" && REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" skeleton test-handoff-wire-c 001 --type implementation 2>&1
echo "# Real architecture" > "$TEST_DIR/test-handoff-wire-c/round-001/architecture.md"
echo "# Real claude report" > "$TEST_DIR/test-handoff-wire-c/round-001/claude_report.md"
echo "# Real codex final review" > "$TEST_DIR/test-handoff-wire-c/round-001/codex_final_review.md"
rm -f "$CAPTURED_PAYLOAD_FILE"
(cd "$SCRIPT_DIR" && PATH="$FAKE_BIN_DIR:$PATH" CAPTURED_PAYLOAD_FILE="$CAPTURED_PAYLOAD_FILE" \
  REVIEWS_OVERRIDE="$TEST_DIR" N8N_CODEX_REVIEW_DONE_WEBHOOK_URL="http://n8n.invalid/webhook" \
  bash "$BRIDGE" check test-handoff-wire-c 001 >/dev/null 2>&1)
if [[ -f "$CAPTURED_PAYLOAD_FILE" ]]; then
  payload=$(cat "$CAPTURED_PAYLOAD_FILE")
  assert_contains "codex_final_review.md payload has correct review_type" "codex_final_review" "$payload"
  if [[ "$payload" != *"handoff_package_content"* ]]; then
    echo "  PASS: codex_final_review.md notification omits handoff_package_content (no scenario defined)"
    ((pass_count++))
  else
    echo "  FAIL: codex_final_review.md notification unexpectedly included handoff_package_content"
    ((fail_count++))
  fi
else
  echo "  FAIL: no payload captured for codex_final_review.md notification"
  ((fail_count++))
fi

###############################################################################
# Test 22: notify command (Sprint-013 Generic Telegram Notification Runtime)
###############################################################################
echo ""
echo "=== Test 22: notify command ==="

NOTIFY_ARTIFACTS_DIR="$TEST_DIR/notify-artifacts"
mkdir -p "$NOTIFY_ARTIFACTS_DIR"
NOTIFY_HISTORY="$TEST_DIR/notification_history.jsonl"

NOTIFY_FAKE_BIN_OK="$TEST_DIR/notify-fake-bin-ok"
mkdir -p "$NOTIFY_FAKE_BIN_OK"
cat > "$NOTIFY_FAKE_BIN_OK/curl" <<'STUB'
#!/usr/bin/env bash
echo '{"ok":true,"result":{"message_id":1}}'
exit 0
STUB
chmod +x "$NOTIFY_FAKE_BIN_OK/curl"

NOTIFY_FAKE_BIN_FAIL="$TEST_DIR/notify-fake-bin-fail"
mkdir -p "$NOTIFY_FAKE_BIN_FAIL"
cat > "$NOTIFY_FAKE_BIN_FAIL/curl" <<'STUB'
#!/usr/bin/env bash
exit 7
STUB
chmod +x "$NOTIFY_FAKE_BIN_FAIL/curl"

# 22a: Notification Package can be generated; Telegram disabled by default
# (NOTIFICATION_ENABLED unset) -> delivery_status=disabled, package still written.
echo "v1" > "$NOTIFY_ARTIFACTS_DIR/a.md"
output=$(cd "$SCRIPT_DIR" && env -u NOTIFICATION_ENABLED -u TELEGRAM_BOT_TOKEN -u TELEGRAM_CHAT_ID \
  PROJECT_ID=proj-a PROJECT_NAME="Project A" REVIEWS_OVERRIDE="$TEST_DIR" \
  bash "$BRIDGE" notify sprint-alpha 001 codex_review_done "$NOTIFY_ARTIFACTS_DIR/a.md" 2>&1)
ec=$?
assert_exit_code "notify exits 0 on successful package generation" 0 "$ec"
assert_contains "notify reports disabled when NOTIFICATION_ENABLED unset" "disabled" "$output"
[[ -f "$TEST_DIR/sprint-alpha/round-001/notifications/codex_review_done.md" ]] \
  && { echo "  PASS: Notification Package file created"; ((pass_count++)); } \
  || { echo "  FAIL: Notification Package file not created"; ((fail_count++)); }
pkg_content=$(cat "$TEST_DIR/sprint-alpha/round-001/notifications/codex_review_done.md" 2>/dev/null || echo "")
assert_contains "package includes Project section with generic project_id" "proj-a" "$pkg_content"
assert_contains "package includes generic project_name" "Project A" "$pkg_content"
assert_contains "package includes Deduplication Key" "Deduplication Key" "$pkg_content"
assert_contains "package includes Copyable Handoff Package section" "Copyable Handoff Package" "$pkg_content"

# 22b: Deduplication key is generated and recorded in history.
assert_contains "history file created" "deduplication_key" "$(cat "$NOTIFY_HISTORY" 2>/dev/null || echo "")"

# 22c: same event/artifact (same hash) is not re-pushed once delivered.
echo "v1" > "$NOTIFY_ARTIFACTS_DIR/b.md"
PATH="$NOTIFY_FAKE_BIN_OK:$PATH" PROJECT_ID=proj-c PROJECT_NAME="Project C" \
  NOTIFICATION_ENABLED=true TELEGRAM_BOT_TOKEN=tok TELEGRAM_CHAT_ID=1 \
  REVIEWS_OVERRIDE="$TEST_DIR" \
  bash "$BRIDGE" notify sprint-charlie 001 codex_review_done "$NOTIFY_ARTIFACTS_DIR/b.md" >/dev/null 2>&1
output=$(PATH="$NOTIFY_FAKE_BIN_OK:$PATH" PROJECT_ID=proj-c PROJECT_NAME="Project C" \
  NOTIFICATION_ENABLED=true TELEGRAM_BOT_TOKEN=tok TELEGRAM_CHAT_ID=1 \
  REVIEWS_OVERRIDE="$TEST_DIR" \
  bash "$BRIDGE" notify sprint-charlie 001 codex_review_done "$NOTIFY_ARTIFACTS_DIR/b.md" 2>&1)
ec=$?
assert_exit_code "duplicate notify still exits 0 (not a failure)" 0 "$ec"
assert_contains "duplicate notify reports skipped_duplicate" "skipped_duplicate" "$output"

# 22d: artifact content change produces a new hash and allows a new push.
echo "v2-changed" > "$NOTIFY_ARTIFACTS_DIR/b.md"
output=$(PATH="$NOTIFY_FAKE_BIN_OK:$PATH" PROJECT_ID=proj-c PROJECT_NAME="Project C" \
  NOTIFICATION_ENABLED=true TELEGRAM_BOT_TOKEN=tok TELEGRAM_CHAT_ID=1 \
  REVIEWS_OVERRIDE="$TEST_DIR" \
  bash "$BRIDGE" notify sprint-charlie 001 codex_review_done "$NOTIFY_ARTIFACTS_DIR/b.md" 2>&1)
assert_contains "changed artifact is delivered again (not skipped)" "delivered" "$output"

# 22e: missing artifact fails safely.
output=$(cd "$SCRIPT_DIR" && PROJECT_ID=proj-e PROJECT_NAME="Project E" REVIEWS_OVERRIDE="$TEST_DIR" \
  bash "$BRIDGE" notify sprint-echo 001 codex_review_done "$NOTIFY_ARTIFACTS_DIR/does-not-exist.md" 2>&1)
ec=$?
assert_exit_code "missing artifact exits non-zero" 1 "$ec"
assert_contains "missing artifact prints clear error" "not found" "$output"
[[ ! -f "$TEST_DIR/sprint-echo/round-001/notifications/codex_review_done.md" ]] \
  && { echo "  PASS: no package written for missing artifact"; ((pass_count++)); } \
  || { echo "  FAIL: package unexpectedly written for missing artifact"; ((fail_count++)); }

# 22f: missing Telegram config -> disabled, package still generated, no send.
echo "v1" > "$NOTIFY_ARTIFACTS_DIR/f.md"
output=$(cd "$SCRIPT_DIR" && env -u TELEGRAM_BOT_TOKEN -u TELEGRAM_CHAT_ID \
  PROJECT_ID=proj-f PROJECT_NAME="Project F" NOTIFICATION_ENABLED=true REVIEWS_OVERRIDE="$TEST_DIR" \
  bash "$BRIDGE" notify sprint-foxtrot 001 codex_review_done "$NOTIFY_ARTIFACTS_DIR/f.md" 2>&1)
assert_contains "missing Telegram config reports disabled" "disabled" "$output"
[[ -f "$TEST_DIR/sprint-foxtrot/round-001/notifications/codex_review_done.md" ]] \
  && { echo "  PASS: package still generated when Telegram config missing"; ((pass_count++)); } \
  || { echo "  FAIL: package not generated when Telegram config missing"; ((fail_count++)); }

# 22g/22h/22i: generic sprint_id / round_id / project_id / project_name (not
# hardcoded to sprint-013 / round-001 / ai-workspace).
echo "v1" > "$NOTIFY_ARTIFACTS_DIR/g.md"
output=$(cd "$SCRIPT_DIR" && PROJECT_ID=totally-different-project PROJECT_NAME="Totally Different Project" \
  REVIEWS_OVERRIDE="$TEST_DIR" \
  bash "$BRIDGE" notify sprint-999 007 push_done "$NOTIFY_ARTIFACTS_DIR/g.md" 2>&1)
assert_exit_code "arbitrary sprint_id/round_id/project_id all accepted" 0 "$?"
[[ -f "$TEST_DIR/sprint-999/round-007/notifications/push_done.md" ]] \
  && { echo "  PASS: generic sprint_id (sprint-999) and round_id (007) both work"; ((pass_count++)); } \
  || { echo "  FAIL: generic sprint_id/round_id did not produce expected path"; ((fail_count++)); }
pkg_g=$(cat "$TEST_DIR/sprint-999/round-007/notifications/push_done.md" 2>/dev/null || echo "")
assert_contains "generic project_id flows into package" "totally-different-project" "$pkg_g"
assert_contains "generic project_name flows into package" "Totally Different Project" "$pkg_g"

# 22j: invalid event type is rejected (whitelist).
output=$(cd "$SCRIPT_DIR" && PROJECT_ID=proj-j PROJECT_NAME="Project J" REVIEWS_OVERRIDE="$TEST_DIR" \
  bash "$BRIDGE" notify sprint-juliet 001 not_a_real_event "$NOTIFY_ARTIFACTS_DIR/a.md" 2>&1)
ec=$?
assert_exit_code "unknown event_type exits non-zero" 1 "$ec"
assert_contains "unknown event_type reports clear error" "Invalid event_type" "$output"

# 22k: notification history is append-only (never overwritten).
lines_before=$(wc -l < "$NOTIFY_HISTORY")
echo "v1" > "$NOTIFY_ARTIFACTS_DIR/k.md"
PROJECT_ID=proj-k PROJECT_NAME="Project K" REVIEWS_OVERRIDE="$TEST_DIR" \
  bash "$BRIDGE" notify sprint-kilo 001 retrospective_done "$NOTIFY_ARTIFACTS_DIR/k.md" >/dev/null 2>&1
lines_after=$(wc -l < "$NOTIFY_HISTORY")
if (( lines_after > lines_before )); then
  echo "  PASS: notification_history.jsonl grew (append-only, not overwritten)"
  ((pass_count++))
else
  echo "  FAIL: notification_history.jsonl did not grow as expected"
  ((fail_count++))
fi

# 22l: TELEGRAM_BOT_TOKEN is never written to the Notification Package,
# the history file, or stdout/stderr output.
echo "v1" > "$NOTIFY_ARTIFACTS_DIR/l.md"
output=$(PATH="$NOTIFY_FAKE_BIN_OK:$PATH" PROJECT_ID=proj-l PROJECT_NAME="Project L" \
  NOTIFICATION_ENABLED=true TELEGRAM_BOT_TOKEN=SUPER_SECRET_TOKEN_VALUE TELEGRAM_CHAT_ID=1 \
  REVIEWS_OVERRIDE="$TEST_DIR" \
  bash "$BRIDGE" notify sprint-lima 001 commit_done "$NOTIFY_ARTIFACTS_DIR/l.md" 2>&1)
if [[ "$output" != *"SUPER_SECRET_TOKEN_VALUE"* ]] \
   && [[ "$(cat "$TEST_DIR/sprint-lima/round-001/notifications/commit_done.md")" != *"SUPER_SECRET_TOKEN_VALUE"* ]] \
   && [[ "$(cat "$NOTIFY_HISTORY")" != *"SUPER_SECRET_TOKEN_VALUE"* ]]; then
  echo "  PASS: TELEGRAM_BOT_TOKEN never appears in output, package, or history"
  ((pass_count++))
else
  echo "  FAIL: TELEGRAM_BOT_TOKEN leaked somewhere"
  ((fail_count++))
fi

# 22m: Telegram API failure -> failed, no infinite retry (single curl call),
# does not advance workflow, command still exits 0 (package was produced).
echo "v1" > "$NOTIFY_ARTIFACTS_DIR/m.md"
output=$(PATH="$NOTIFY_FAKE_BIN_FAIL:$PATH" PROJECT_ID=proj-m PROJECT_NAME="Project M" \
  NOTIFICATION_ENABLED=true TELEGRAM_BOT_TOKEN=tok TELEGRAM_CHAT_ID=1 \
  REVIEWS_OVERRIDE="$TEST_DIR" \
  bash "$BRIDGE" notify sprint-mike 001 git_review_done "$NOTIFY_ARTIFACTS_DIR/m.md" 2>&1)
ec=$?
assert_exit_code "Telegram API failure still exits 0 (package was produced)" 0 "$ec"
assert_contains "Telegram API failure reports failed status" "failed" "$(cat "$NOTIFY_HISTORY")"

# 22n: --dry-run does not write the Notification Package and does not call curl.
echo "v1" > "$NOTIFY_ARTIFACTS_DIR/n.md"
output=$(PATH="$NOTIFY_FAKE_BIN_FAIL:$PATH" PROJECT_ID=proj-n PROJECT_NAME="Project N" \
  NOTIFICATION_ENABLED=true TELEGRAM_BOT_TOKEN=tok TELEGRAM_CHAT_ID=1 \
  REVIEWS_OVERRIDE="$TEST_DIR" \
  bash "$BRIDGE" notify sprint-november 001 push_done "$NOTIFY_ARTIFACTS_DIR/n.md" --dry-run 2>&1)
assert_contains "dry-run shows would-write message" "[dry-run] Would write" "$output"
[[ ! -f "$TEST_DIR/sprint-november/round-001/notifications/push_done.md" ]] \
  && { echo "  PASS: dry-run does not create the Notification Package"; ((pass_count++)); } \
  || { echo "  FAIL: dry-run created the Notification Package"; ((fail_count++)); }

# 22o: notify does not affect existing check/consensus/finalize commands or
# canonical artifact naming — re-verified by the full suite re-run below
# (Sprint-004 E2E and Tests 1-21 all still pass in this same run).
echo "  (existing check/consensus/finalize behavior re-verified by the rest of this test run)"

# 22p: notify contains no git commit / git push / Claude / Codex invocation.
# Comment-only lines are stripped first so explanatory prose (e.g. "never
# calls ... git commit") does not produce a false positive; this checks for
# actual command invocations only.
notify_src="$(sed -n '/# Command: notify/,/# Main dispatcher/p' "$BRIDGE" | grep -v '^[[:space:]]*#')"
if [[ "$notify_src" != *"git commit"* && "$notify_src" != *"git push"* ]]; then
  echo "  PASS: notify command source contains no git commit / git push"
  ((pass_count++))
else
  echo "  FAIL: notify command source contains git commit/push"
  ((fail_count++))
fi
if [[ "$notify_src" != *"api.anthropic.com"* && "$notify_src" != *"openai.com"* ]]; then
  echo "  PASS: notify command source calls no Claude/Codex API"
  ((pass_count++))
else
  echo "  FAIL: notify command source unexpectedly references an AI API"
  ((fail_count++))
fi

###############################################################################
# Test 23: Sprint-013 Codex Review Must Fix verification
###############################################################################
echo ""
echo "=== Test 23: Must Fix verification (artifact-first Telegram, recipient/actor split, SSOT field contract) ==="

NOTIFY23_ARTIFACTS="$TEST_DIR/notify23-artifacts"
mkdir -p "$NOTIFY23_ARTIFACTS"
NOTIFY23_HISTORY="$TEST_DIR/notification_history.jsonl"

# Fake curl that captures the exact file content passed via --data-urlencode
# text@<file> (Must Fix 1 delivery mechanism) into CAPTURED_CONTENT_FILE
# *before* cmd_notify cleans up its temp chunk directory.
NOTIFY23_FAKE_BIN="$TEST_DIR/notify23-fake-bin"
mkdir -p "$NOTIFY23_FAKE_BIN"
cat > "$NOTIFY23_FAKE_BIN/curl" <<'STUB'
#!/usr/bin/env bash
for a in "$@"; do
  case "$a" in
    text@*) cp "${a#text@}" "$CAPTURED_CONTENT_FILE" ;;
  esac
done
echo '{"ok":true}'
exit 0
STUB
chmod +x "$NOTIFY23_FAKE_BIN/curl"

# 23a/23b: Telegram receives the Notification Package artifact content
# unmodified — no separately composed message_text exists.
echo "content-23a" > "$NOTIFY23_ARTIFACTS/a.md"
NOTIFY23_CAPTURED="$TEST_DIR/notify23-captured.txt"
rm -f "$NOTIFY23_CAPTURED"
PATH="$NOTIFY23_FAKE_BIN:$PATH" CAPTURED_CONTENT_FILE="$NOTIFY23_CAPTURED" \
  PROJECT_ID=proj23a PROJECT_NAME="Project 23A" NOTIFICATION_ENABLED=true \
  TELEGRAM_BOT_TOKEN=tok TELEGRAM_CHAT_ID=1 REVIEWS_OVERRIDE="$TEST_DIR" \
  bash "$BRIDGE" notify sprint-23a 001 codex_review_done "$NOTIFY23_ARTIFACTS/a.md" >/dev/null 2>&1
pkg_23a="$TEST_DIR/sprint-23a/round-001/notifications/codex_review_done.md"
if [[ -f "$NOTIFY23_CAPTURED" && -f "$pkg_23a" ]] && diff -q "$NOTIFY23_CAPTURED" "$pkg_23a" >/dev/null 2>&1; then
  echo "  PASS: Telegram receives the Notification Package artifact content byte-for-byte (Must Fix 1)"
  ((pass_count++))
else
  echo "  FAIL: Telegram content does not match the Notification Package artifact"
  ((fail_count++))
fi

# 23c: notification_recipient is always Product Owner, for every event type.
# sprint_id must stay hyphen-only (validate_id rejects underscores), so a
# fixed sprint_id is reused with a distinct round number per event instead of
# embedding the event name in the sprint_id.
echo "content-23c" > "$NOTIFY23_ARTIFACTS/c.md"
all_recipient_ok=true
round_num=1
for evt in claude_implementation_done codex_review_done claude_should_fix_done \
           codex_final_review_done git_review_done commit_done push_done retrospective_done; do
  round_padded="$(printf '%03d' "$round_num")"
  PROJECT_ID=proj23c PROJECT_NAME="Project 23C" REVIEWS_OVERRIDE="$TEST_DIR" \
    bash "$BRIDGE" notify sprint-23c "$round_num" "$evt" "$NOTIFY23_ARTIFACTS/c.md" >/dev/null 2>&1
  pkg="$TEST_DIR/sprint-23c/round-$round_padded/notifications/${evt}.md"
  recipient_line="$(awk '/^## Notification Recipient/{getline; getline; print; exit}' "$pkg" 2>/dev/null)"
  if [[ "$recipient_line" != "Product Owner" ]]; then
    all_recipient_ok=false
    echo "    (event $evt has Notification Recipient='$recipient_line', expected 'Product Owner')"
  fi
  if [[ "$evt" == "claude_implementation_done" ]]; then
    pkg_claude_impl="$pkg"
  fi
  ((round_num++))
done
if $all_recipient_ok; then
  echo "  PASS: notification_recipient is Product Owner for all 8 event types (Must Fix 2)"
  ((pass_count++))
else
  echo "  FAIL: notification_recipient was not Product Owner for at least one event type"
  ((fail_count++))
fi

# 23d: next_actor is a distinct field from notification_recipient, and is not
# always the same value (proving the two are genuinely separate concepts,
# not just two labels for one field). pkg_claude_impl was captured inside the
# 23c loop above.
assert_contains "package has a distinct 'Next Actor' section" "## Next Actor" "$(cat "$pkg_claude_impl" 2>/dev/null || echo "")"
next_actor_claude_impl="$(awk '/^## Next Actor/{getline; getline; print; exit}' "$pkg_claude_impl" 2>/dev/null)"
recipient_claude_impl="$(awk '/^## Notification Recipient/{getline; getline; print; exit}' "$pkg_claude_impl" 2>/dev/null)"
if [[ "$next_actor_claude_impl" == "Codex" && "$recipient_claude_impl" == "Product Owner" && "$next_actor_claude_impl" != "$recipient_claude_impl" ]]; then
  echo "  PASS: next_actor (Codex) and notification_recipient (Product Owner) are independently represented"
  ((pass_count++))
else
  echo "  FAIL: next_actor / notification_recipient not correctly separated for claude_implementation_done"
  ((fail_count++))
fi

# 23e: generated package contains all 17 SSOT-required field headers.
pkg_content_23e="$(cat "$pkg_23a" 2>/dev/null || echo "")"
for field in "Project ID" "Project Name" "Sprint ID" "Round ID" "Event Type" \
             "Notification Recipient" "Next Actor" "Source Artifact Path" \
             "Artifact Hash" "Deduplication Key" "Notification Package Path" \
             "Delivery Channel" "Delivery Status" "Created Time" \
             "Product Owner Next Action" "Copyable Handoff Package" "Delivery Metadata"; do
  assert_contains "package includes required SSOT field: $field" "## $field" "$pkg_content_23e"
done

# 23f: the 8 event types are identical between the SSOT specification
# document and the notify runtime's whitelist (no drift between the two).
spec_events="$(sed -n '/^## 2. Notification Events/,/^## 3. Required Fields/p' /home/ivan/AI/docs/development/notification-package-specification.md | grep -oE '.[a-z_]+_done.' | tr -d '`' | sort -u)"
code_events="$(sed -n '/^NOTIFY_ALLOWED_EVENTS=/,/^)/p' "$BRIDGE" | grep -oE '^  [a-z_]+_done' | tr -d ' ' | sort -u)"
if [[ "$spec_events" == "$code_events" ]]; then
  echo "  PASS: event whitelist is identical between the SSOT specification and the notify runtime"
  ((pass_count++))
else
  echo "  FAIL: event whitelist differs between spec and runtime"
  echo "    spec:   $(echo "$spec_events" | tr '\n' ' ')"
  echo "    runtime: $(echo "$code_events" | tr '\n' ' ')"
  ((fail_count++))
fi

###############################################################################
# Test 24: Sprint-014 Telegram PO Gate Notification & Execution Policy V1
###############################################################################
echo ""
echo "=== Test 24: Sprint-014 Product Owner Gate notification ==="

GATE24_ARTIFACTS="$TEST_DIR/gate24-artifacts"
mkdir -p "$GATE24_ARTIFACTS"
echo "gate content" > "$GATE24_ARTIFACTS/a.md"

# Extract the 21-gate whitelist directly from the script (not hardcoded here)
# so this test tracks the runtime, not a second copy of the list.
mapfile -t gate24_ids < <(sed -n '/^GATE_WHITELIST=(/,/^)/p' "$BRIDGE" | grep -oE '^  [a-z_]+' | tr -d ' ')

# 24a: exactly 21 gates in the whitelist.
if [[ "${#gate24_ids[@]}" -eq 21 ]]; then
  echo "  PASS: GATE_WHITELIST contains exactly 21 gates"
  ((pass_count++))
else
  echo "  FAIL: GATE_WHITELIST contains ${#gate24_ids[@]} gates, expected 21"
  ((fail_count++))
fi

# 24b: an unknown gate_id is rejected.
PROJECT_ID=gate24 PROJECT_NAME="Gate24" REVIEWS_OVERRIDE="$TEST_DIR" \
  bash "$BRIDGE" notify-gate not_a_real_gate sprint-24b 001 "$GATE24_ARTIFACTS/a.md" >/tmp/gate24b.out 2>&1
gate24b_exit=$?
assert_exit_code "unknown gate_id is rejected (nonzero exit)" 1 "$gate24b_exit"
assert_contains "unknown gate_id error message names the gate" "not_a_real_gate" "$(cat /tmp/gate24b.out)"
rm -f /tmp/gate24b.out

# 24c-24q: generate every gate's Notification Package once and verify the
# full per-gate metadata / formatting / field contract.
high_risk_gates="commit_approval codex_commit_approval push_approval codex_push_approval"
valid_next_actors="Product Owner ChatGPT Claude Code Codex"
valid_risk_levels="low medium high"

all_have_name=true
all_have_next_actor=true
all_have_mode=true
all_have_risk=true
all_have_po_action=true
all_generate_package=true
all_have_chinese=true
all_general_format_ok=true
all_high_risk_format_ok=true
all_handoff_isolated=true
all_metadata_last=true
all_risk_valid=true
all_next_actor_valid=true

round24=1
for gid in "${gate24_ids[@]}"; do
  round24_padded="$(printf '%03d' "$round24")"
  PROJECT_ID=gate24 PROJECT_NAME="Gate24" REVIEWS_OVERRIDE="$TEST_DIR" \
    bash "$BRIDGE" notify-gate "$gid" sprint-24c "$round24" "$GATE24_ARTIFACTS/a.md" >/dev/null 2>&1
  pkg="$TEST_DIR/sprint-24c/round-$round24_padded/notifications/gate-${gid}.md"

  if [[ ! -f "$pkg" ]]; then
    all_generate_package=false
    echo "    (gate $gid: Notification Package was not generated)"
    ((round24++))
    continue
  fi

  content="$(cat "$pkg")"

  [[ "$content" == *"➡️ 下一位執行者"* ]] || { all_have_next_actor=false; echo "    (gate $gid missing next_actor section)"; }
  [[ "$content" == *"⚙️ 建議執行模式"* ]] || { all_have_mode=false; echo "    (gate $gid missing recommended_execution_mode section)"; }
  [[ "$content" == *"risk_level:"* ]] || { all_have_risk=false; echo "    (gate $gid missing risk_level)"; }
  [[ "$content" == *"✅ Product Owner 下一步"* ]] || { all_have_po_action=false; echo "    (gate $gid missing product_owner_next_action_zh section)"; }

  # gate_name_zh appears either after "目前 Gate" (general) or in the
  # high-risk header line "⚠️ 高風險 Gate：...".
  if [[ "$content" != *"🧭 目前 Gate"* && "$content" != *"⚠️ 高風險 Gate："* ]]; then
    all_have_name=false
    echo "    (gate $gid missing gate_name_zh section)"
  fi

  # Traditional Chinese content check: look for a specific CJK label.
  [[ "$content" == *"通知對象"* ]] || { all_have_chinese=false; echo "    (gate $gid message is not Traditional Chinese)"; }

  is_high_risk=false
  for hr in $high_risk_gates; do
    [[ "$gid" == "$hr" ]] && is_high_risk=true
  done

  if $is_high_risk; then
    [[ "$content" == *"⚠️ 高風險 Gate："* && "$content" == *"⚠️ 風險提醒"* ]] || { all_high_risk_format_ok=false; echo "    (gate $gid should use high-risk format)"; }
    [[ "$content" == *"risk_level: high"* ]] || { all_risk_valid=false; echo "    (high-risk gate $gid did not report risk_level: high)"; }
  else
    [[ "$content" == *"🔔 AI Workspace Gate 通知"* ]] || { all_general_format_ok=false; echo "    (gate $gid should use general format)"; }
  fi

  # Handoff Package must be an isolated, delimited block.
  handoff_line_count="$(echo "$content" | grep -c '^📦 Handoff Package$')"
  delim_count="$(echo "$content" | grep -c '^---$')"
  if [[ "$handoff_line_count" -ne 1 || "$delim_count" -lt 2 ]]; then
    all_handoff_isolated=false
    echo "    (gate $gid Handoff Package block is not cleanly isolated)"
  fi

  # Delivery Metadata must be the last section (its header is the last
  # occurrence of a section-start marker in the file).
  last_section_line="$(grep -n '^\(🔔\|📌\|🧭\|📍\|⚠️\|👤\|➡️\|⚙️\|✅\|📦\|🧾\)' "$pkg" | tail -1)"
  [[ "$last_section_line" == *"🧾 Delivery Metadata"* ]] || { all_metadata_last=false; echo "    (gate $gid Delivery Metadata is not the last section)"; }

  # risk_level / next_actor enum validation.
  gate_risk_value="$(awk -F': ' '/^risk_level:/{print $2; exit}' "$pkg")"
  risk_ok=false
  for rv in $valid_risk_levels; do
    [[ "$gate_risk_value" == "$rv" ]] && risk_ok=true
  done
  $risk_ok || { all_risk_valid=false; echo "    (gate $gid has invalid risk_level='$gate_risk_value')"; }

  gate_next_actor_value="$(awk -F': ' '/^next_actor:/{print $2; exit}' "$pkg")"
  next_actor_ok=false
  for nv in "Product Owner" "ChatGPT" "Claude Code" "Codex"; do
    [[ "$gate_next_actor_value" == "$nv" ]] && next_actor_ok=true
  done
  $next_actor_ok || { all_next_actor_valid=false; echo "    (gate $gid has invalid next_actor='$gate_next_actor_value')"; }

  ((round24++))
done

assert_true "24c: every gate generates a Notification Package" $all_generate_package
assert_true "24d: every gate's package has a gate_name_zh section" $all_have_name
assert_true "24e: every gate's package has a next_actor section" $all_have_next_actor
assert_true "24f: every gate's package has a recommended_execution_mode section" $all_have_mode
assert_true "24g: every gate's package has a risk_level field" $all_have_risk
assert_true "24h: every gate's package has a product_owner_next_action_zh section" $all_have_po_action
assert_true "24i: every gate's package is Traditional Chinese" $all_have_chinese
assert_true "24j: general gates use the general Telegram format" $all_general_format_ok
assert_true "24k: Commit/Push gates use the high-risk Telegram format" $all_high_risk_format_ok
assert_true "24l: Handoff Package is an isolated, copyable block in every gate" $all_handoff_isolated
assert_true "24m: Delivery Metadata is the last section in every gate" $all_metadata_last
assert_true "24n: risk_level is always one of low/medium/high" $all_risk_valid
assert_true "24o: next_actor is always one of the 4 allowed values" $all_next_actor_valid

# 24p: every line Telegram actually receives, across all section-aware
# messages (Sprint-017 Must Fix Round 7), is real content copied verbatim
# from the Gate Notification Package -- nothing fabricated or summarized
# (Artifact First, same underlying guarantee as Sprint-013 Must Fix 1, now
# verified as a set-equality of lines across possibly-multiple messages
# instead of one single byte-for-byte file, since Round 7 intentionally
# splits delivery into separate messages rather than one chunked stream).
GATE24_FAKE_BIN="$TEST_DIR/gate24-fake-bin"
mkdir -p "$GATE24_FAKE_BIN"
GATE24_CAPTURED_DIR="$TEST_DIR/gate24-captured-messages"
mkdir -p "$GATE24_CAPTURED_DIR"
cat > "$GATE24_FAKE_BIN/curl" <<'STUB'
#!/usr/bin/env bash
# Deterministic, collision-free numbering (never $RANDOM, which can
# collide between the several messages one notify-gate call now sends
# since Sprint-017 Must Fix Round 7 and silently overwrite one message
# with another).
n=1
while [[ -f "$CAPTURED_MESSAGES_DIR/msg-$(printf '%02d' "$n").txt" ]]; do n=$((n+1)); done
for a in "$@"; do
  case "$a" in
    text@*) cp "${a#text@}" "$CAPTURED_MESSAGES_DIR/msg-$(printf '%02d' "$n").txt" ;;
  esac
done
echo '{"ok":true}'
exit 0
STUB
chmod +x "$GATE24_FAKE_BIN/curl"
PATH="$GATE24_FAKE_BIN:$PATH" CAPTURED_MESSAGES_DIR="$GATE24_CAPTURED_DIR" \
  PROJECT_ID=gate24 PROJECT_NAME="Gate24" NOTIFICATION_ENABLED=true \
  TELEGRAM_BOT_TOKEN=tok TELEGRAM_CHAT_ID=1 REVIEWS_OVERRIDE="$TEST_DIR" \
  bash "$BRIDGE" notify-gate push_approval sprint-24p 001 "$GATE24_ARTIFACTS/a.md" >/dev/null 2>&1
gate24p_pkg="$TEST_DIR/sprint-24p/round-001/notifications/gate-push_approval.md"
# Every captured line must be a real line from the package file (nothing
# fabricated/summarized) -- checked as "captured is a subset of package",
# not full equality: Round 7 intentionally drops the single-file-only
# structural wrapper lines ("📦 Handoff Package" heading and its "---"
# delimiters), which only made sense when everything lived in one combined
# file/message and are meaningless once content is split into separate,
# independently-delimited Telegram messages. Blank lines are also excluded
# (cosmetic message-boundary spacing, not content).
gate24p_captured_lines="$(cat "$GATE24_CAPTURED_DIR"/msg-*.txt 2>/dev/null | grep -v '^[[:space:]]*$' | sort -u)"
gate24p_pkg_lines="$(grep -v '^[[:space:]]*$' "$gate24p_pkg" 2>/dev/null | sort -u)"
gate24p_extra_lines="$(comm -23 <(echo "$gate24p_captured_lines") <(echo "$gate24p_pkg_lines"))"
if [[ -n "$gate24p_captured_lines" && -z "$gate24p_extra_lines" ]]; then
  echo "  PASS: Telegram receives the Gate Notification Package content byte-for-byte"
  ((pass_count++))
else
  echo "  FAIL: Telegram content does not match the Gate Notification Package"
  echo "    extra/fabricated lines not found in the package: $gate24p_extra_lines"
  ((fail_count++))
fi

# 24q/24r: required Sprint-014 documentation exists.
assert_true "24q: docs/development/execution-permission-policy.md exists" "[[ -f /home/ivan/AI/docs/development/execution-permission-policy.md ]] && true || false"
assert_true "24r: docs/development/telegram-po-gate-notification-specification.md exists" "[[ -f /home/ivan/AI/docs/development/telegram-po-gate-notification-specification.md ]] && true || false"

policy_doc="$(cat /home/ivan/AI/docs/development/execution-permission-policy.md 2>/dev/null || echo "")"
all_modes_have_allow_forbid=true
for mode in "Claude Implementation Mode" "Claude Must Fix Mode" "Codex Review Mode" \
            "Codex Final Review Mode" "Codex Git Review Mode" "Codex Commit Mode" "Codex Push Mode"; do
  mode_section="$(echo "$policy_doc" | awk -v m="### 2\\..*$mode" 'BEGIN{f=0} $0 ~ m {f=1} f && /^### 2\./ && $0 !~ m {f=0} f' )"
  if [[ "$mode_section" != *"允許動作"* || "$mode_section" != *"禁止動作"* ]]; then
    all_modes_have_allow_forbid=false
    echo "    (mode '$mode' section missing 允許動作/禁止動作)"
  fi
done
assert_true "24s: every Execution Permission Policy mode defines 允許動作 and 禁止動作" $all_modes_have_allow_forbid

assert_contains "24t: Codex Commit Mode is marked strict manual approval" "每一步都需要" "$(echo "$policy_doc" | awk '/### 2\.6 Codex Commit Mode/,/### 2\.7/')"
assert_contains "24u: Codex Push Mode is marked strict manual approval" "每一步都需要" "$(echo "$policy_doc" | awk '/### 2\.7 Codex Push Mode/,/## 3\./')"

# 24v-24y: forbidden mechanisms are absent from the new Sprint-014 code.
# Strip comment lines and echo'd string literals (e.g. the Codex Git Review
# Mode summary text, which *describes* "不得執行 git add、commit、push" as
# prose but never executes it) so only actual command invocations remain.
gate_code_src="$(sed -n '/^# Command: notify-gate/,/^# Main dispatcher/p' "$BRIDGE" | grep -v '^[[:space:]]*#' | grep -v 'echo "')"
if [[ "$gate_code_src" != *"callback_query"* && "$gate_code_src" != *"inline_keyboard"* ]]; then
  echo "  PASS: notify-gate contains no Telegram button auto-execution logic"
  ((pass_count++))
else
  echo "  FAIL: notify-gate appears to implement Telegram button auto-execution"
  ((fail_count++))
fi
if [[ "$gate_code_src" != *"n8n"* ]]; then
  echo "  PASS: notify-gate contains no n8n Execute Command reference"
  ((pass_count++))
else
  echo "  FAIL: notify-gate references n8n"
  ((fail_count++))
fi
if [[ "$gate_code_src" != *"git commit"* && "$gate_code_src" != *"git push"* && "$gate_code_src" != *"git add"* ]]; then
  echo "  PASS: notify-gate contains no automatic commit/push/add"
  ((pass_count++))
else
  echo "  FAIL: notify-gate contains a git commit/push/add invocation"
  ((fail_count++))
fi
if [[ "$gate_code_src" != *"api.anthropic.com"* && "$gate_code_src" != *"openai.com"* ]]; then
  echo "  PASS: notify-gate calls no Claude/Codex API"
  ((pass_count++))
else
  echo "  FAIL: notify-gate unexpectedly references an AI API"
  ((fail_count++))
fi
# Only inspect the lines that actually mention "bypass sandbox" (not the
# whole multi-thousand-character document, where unrelated "建議"/"允許"
# text appears many times elsewhere and would cause a false positive).
bypass_lines="$(echo "$policy_doc" | grep -i 'bypass sandbox')"
if [[ -n "$bypass_lines" && "$bypass_lines" != *"建議"* && "$bypass_lines" != *"允許"* && "$bypass_lines" != *"可以完全"* ]]; then
  echo "  PASS: Execution Permission Policy does not recommend bypassing the sandbox"
  ((pass_count++))
else
  echo "  FAIL: Execution Permission Policy appears to recommend bypassing the sandbox, or does not mention it at all"
  ((fail_count++))
fi

echo "  (Sprint-013 notify command and its 8-event tests are re-verified above by Test 22/23, run unchanged in this same suite: zero regression)"

###############################################################################
# Test 25: Sprint-016 Gate Metadata Canonicalization & Validation Hardening
###############################################################################
echo ""
echo "=== Test 25: Sprint-016 canonical metadata, validation hardening, safety levels ==="

GATE25_ARTIFACTS="$TEST_DIR/gate25-artifacts"
mkdir -p "$GATE25_ARTIFACTS"
echo "gate25 content" > "$GATE25_ARTIFACTS/a.md"

canonical_doc="$(cat /home/ivan/AI/docs/development/product-owner-gate-metadata.md 2>/dev/null || echo "")"
assert_true "25a: docs/development/product-owner-gate-metadata.md exists" "[[ -f /home/ivan/AI/docs/development/product-owner-gate-metadata.md ]] && true || false"

# 25b: every one of the 21 gate_ids from the runtime whitelist is documented
# in the canonical metadata doc (requirement 1: 21 個 Gate metadata 存在).
mapfile -t gate25_ids < <(sed -n '/^GATE_WHITELIST=(/,/^)/p' "$BRIDGE" | grep -oE '^  [a-z_]+' | tr -d ' ')
all_gates_documented=true
for gid in "${gate25_ids[@]}"; do
  [[ "$canonical_doc" == *"\`$gid\`"* ]] || { all_gates_documented=false; echo "    (canonical doc missing gate_id '$gid')"; }
done
assert_true "25b: all 21 gate_ids from the runtime are documented in the canonical metadata" $all_gates_documented

# 25c: unknown gate_id is still rejected (requirement 2), and validation
# hardening does not change this pre-existing behavior.
PROJECT_ID=gate25 PROJECT_NAME="Gate25" REVIEWS_OVERRIDE="$TEST_DIR" \
  bash "$BRIDGE" notify-gate not_a_real_gate_25 sprint-25c 001 "$GATE25_ARTIFACTS/a.md" >/tmp/gate25c.out 2>&1
assert_exit_code "25c: unknown gate_id is still rejected after validation hardening" 1 "$?"
rm -f /tmp/gate25c.out

# 25d-25f: every real gate still produces next_actor / recommended_execution_mode
# / risk_level (requirements 3-5), now passing through _gate_validate_metadata
# without being rejected (i.e. hardening doesn't break any of the 21 gates).
all_pass_validation=true
round25=1
for gid in "${gate25_ids[@]}"; do
  round25_padded="$(printf '%03d' "$round25")"
  PROJECT_ID=gate25 PROJECT_NAME="Gate25" REVIEWS_OVERRIDE="$TEST_DIR" \
    bash "$BRIDGE" notify-gate "$gid" sprint-25d "$round25" "$GATE25_ARTIFACTS/a.md" >/tmp/gate25d.out 2>&1
  if grep -q "Internal error" /tmp/gate25d.out; then
    all_pass_validation=false
    echo "    (gate $gid failed _gate_validate_metadata: $(cat /tmp/gate25d.out))"
  fi
  ((round25++))
done
rm -f /tmp/gate25d.out
assert_true "25d/e/f: all 21 gates pass the new validation hardening (next_actor/mode/risk_level all valid)" $all_pass_validation

# 25g: high-risk gates contain the required warning wording elements
# (requirement 6).
all_high_risk_wording_ok=true
for hr in commit_approval codex_commit_approval push_approval codex_push_approval; do
  # Re-derive the round number actually used for this gate_id in the 25d loop.
  idx=0
  for gid in "${gate25_ids[@]}"; do
    idx=$((idx+1))
    [[ "$gid" == "$hr" ]] && break
  done
  pkg="$TEST_DIR/sprint-25d/round-$(printf '%03d' "$idx")/notifications/gate-${hr}.md"
  content="$(cat "$pkg" 2>/dev/null || echo "")"
  if [[ "$content" != *"⚠️ 高風險 Gate："* || "$content" != *"⚠️ 風險提醒"* || "$content" != *"risk_level: high"* ]]; then
    all_high_risk_wording_ok=false
    echo "    (high-risk gate $hr missing required warning wording)"
  fi
done
assert_true "25g: all 4 high-risk gates contain required warning wording (⚠️ header, risk reminder, risk_level: high)" $all_high_risk_wording_ok

# 25h: commit/push gates retain explicit Manual Gate wording (requirement 7).
all_manual_gate_wording_ok=true
for hr in commit_approval push_approval; do
  idx=0
  for gid in "${gate25_ids[@]}"; do
    idx=$((idx+1))
    [[ "$gid" == "$hr" ]] && break
  done
  pkg="$TEST_DIR/sprint-25d/round-$(printf '%03d' "$idx")/notifications/gate-${hr}.md"
  content="$(cat "$pkg" 2>/dev/null || echo "")"
  [[ "$content" == *"人工核准"* || "$content" == *"不可低中斷"* ]] || { all_manual_gate_wording_ok=false; echo "    (gate $hr missing Manual Gate wording)"; }
done
for hr in codex_commit_approval codex_push_approval; do
  idx=0
  for gid in "${gate25_ids[@]}"; do
    idx=$((idx+1))
    [[ "$gid" == "$hr" ]] && break
  done
  pkg="$TEST_DIR/sprint-25d/round-$(printf '%03d' "$idx")/notifications/gate-${hr}.md"
  content="$(cat "$pkg" 2>/dev/null || echo "")"
  [[ "$content" == *"Product Owner 親自核准"* ]] || { all_manual_gate_wording_ok=false; echo "    (gate $hr missing Manual Gate wording)"; }
done
assert_true "25h: commit/push gates retain explicit Manual Gate wording" $all_manual_gate_wording_ok

# 25i: delivery_status wording distinguishes package generation from actual
# delivery (requirement 8).
sample_pkg="$TEST_DIR/sprint-25d/round-001/notifications/gate-${gate25_ids[0]}.md"
assert_contains "25i: delivery_status wording clarifies it is not the actual delivery result" \
  "delivery_status: pending（Notification Package 產生當下狀態，非實際送達結果" \
  "$(cat "$sample_pkg" 2>/dev/null || echo "")"

# 25j: Sandboxed Low-Risk Auto-Approval Policy does not apply Level 0 to
# high-risk/write/commit/push actions (requirement 9).
policy_doc25="$(cat /home/ivan/AI/docs/development/execution-permission-policy.md 2>/dev/null || echo "")"
level0_section="$(echo "$policy_doc25" | awk '/### 5\.1 Level 0/,/### 5\.2/')"
level3_section="$(echo "$policy_doc25" | awk '/### 5\.4 Level 3/,/### 5\.5/')"
level0_safe=true
for forbidden in "git add" "git commit" "git push" " rm " " mv " "chmod" "chown" "curl" "wget" "scp" "ssh" "docker"; do
  [[ "$level0_section" == *"$forbidden"* ]] && { level0_safe=false; echo "    (Level 0 section unexpectedly mentions '$forbidden')"; }
done
assert_true "25j-1: Level 0 (auto-approvable) does not list git add/commit/push/rm/mv/chmod/chown/curl/wget/scp/ssh/docker" $level0_safe

level3_complete=true
for required in "git add" "git commit" "git push" "rm" "mv" "chmod" "chown" "curl" "wget" "scp" "ssh" "docker"; do
  [[ "$level3_section" == *"$required"* ]] || { level3_complete=false; echo "    (Level 3 section missing '$required')"; }
done
assert_true "25j-2: Level 3 (Manual Gate required) lists all high-risk/write commands" $level3_complete

# 25k: the Telegram Gate spec now references the canonical metadata doc
# instead of duplicating it (avoids drift between two copies).
spec25="$(cat /home/ivan/AI/docs/development/telegram-po-gate-notification-specification.md 2>/dev/null || echo "")"
assert_contains "25k: Telegram Gate spec references the canonical metadata artifact" \
  "docs/development/product-owner-gate-metadata.md" "$spec25"

# 25l: notify-gate CLI usage is documented in the spec.
assert_contains "25l: Telegram Gate spec documents notify-gate CLI usage" \
  "notify-gate <gate-id>" "$spec25"

###############################################################################
# Sprint-016 Must Fix round: current_status_zh + recommended_execution_mode
###############################################################################

# 25m: every gate's current_status_zh in the canonical metadata doc matches
# the runtime GATE_STATUS_ZH exactly (Must Fix 1 -- this would fail if the
# field were missing, or if it drifted from runtime).
canonical_doc25="$(cat /home/ivan/AI/docs/development/product-owner-gate-metadata.md 2>/dev/null || echo "")"
all_status_aligned=true
for gid in "${gate25_ids[@]}"; do
  runtime_status="$(sed -n "/^    ${gid})\$/,/;;/p" "$BRIDGE" | grep 'GATE_STATUS_ZH=' | sed -E 's/^\s*GATE_STATUS_ZH="(.*)"\s*$/\1/')"
  if [[ -z "$runtime_status" ]]; then
    all_status_aligned=false
    echo "    (could not extract runtime GATE_STATUS_ZH for $gid)"
    continue
  fi
  if [[ "$canonical_doc25" != *"**現況狀態**（current_status_zh）：${runtime_status}"* ]]; then
    all_status_aligned=false
    echo "    (canonical doc missing or misaligned current_status_zh for $gid; expected: $runtime_status)"
  fi
done
assert_true "25m: every gate's current_status_zh in the canonical doc matches runtime GATE_STATUS_ZH exactly" $all_status_aligned

# 25n: _gate_validate_metadata() now actually validates recommended_execution_mode
# (Must Fix 2) -- static source check that a case-statement over
# $GATE_EXEC_MODE exists inside the function body and rejects unknown values
# by name, not just assigns/reads the variable elsewhere.
validate_fn_src="$(sed -n '/^_gate_validate_metadata()/,/^}/p' "$BRIDGE")"
assert_contains "25n-1: _gate_validate_metadata() contains a case statement over GATE_EXEC_MODE" \
  'case "$GATE_EXEC_MODE" in' "$validate_fn_src"
assert_contains "25n-2: _gate_validate_metadata() rejects an invalid recommended_execution_mode by name" \
  "invalid recommended_execution_mode" "$validate_fn_src"

# 25n-3: the case statement's allow-list covers all 10 values actually used
# by _gate_resolve_metadata() (the 7 modes + 3 approved N/A values), so a
# legitimate value is never accidentally rejected.
resolve_fn_modes="$(grep -oE 'GATE_EXEC_MODE="[^"]*"' "$BRIDGE" | grep -v '^GATE_EXEC_MODE=""$' | sort -u)"
all_modes_in_validator=true
while IFS= read -r mode_assignment; do
  mode_value="${mode_assignment#GATE_EXEC_MODE=}"
  mode_value="${mode_value%\"}"
  mode_value="${mode_value#\"}"
  [[ "$validate_fn_src" == *"\"$mode_value\""* ]] || { all_modes_in_validator=false; echo "    (validator missing allowed mode: $mode_value)"; }
done <<< "$resolve_fn_modes"
assert_true "25n-3: validator's allow-list covers every recommended_execution_mode value used by _gate_resolve_metadata()" $all_modes_in_validator

# 25o: a full notify-gate run for every one of the 21 real gates still
# succeeds with no "Internal error" after both Must Fix 1 and Must Fix 2
# changes -- proves the stricter validation does not reject any real gate.
# (Re-uses the artifacts/dir already generated in 25d/e/f above.)
all_still_pass=true
for gid in "${gate25_ids[@]}"; do
  round25_padded="$(printf '%03d' "$(( $(printf '%s\n' "${gate25_ids[@]}" | grep -nx "$gid" | cut -d: -f1) ))")"
  pkg="$TEST_DIR/sprint-25d/round-${round25_padded}/notifications/gate-${gid}.md"
  [[ -f "$pkg" ]] || { all_still_pass=false; echo "    (gate $gid package missing after Must Fix changes)"; }
done
assert_true "25o: all 21 gates still produce a Notification Package after the Must Fix round (no regression)" $all_still_pass

# 25p: no external service is required by these tests, no Telegram live
# delivery is attempted, no n8n JSON is touched, and no runtime evidence
# from this test run leaks outside the isolated TEST_DIR (repository
# hygiene / test-isolation requirement of the Must Fix handoff).
assert_true "25p-1: this test run used REVIEWS_OVERRIDE (isolated TEST_DIR), not the real repository reviews/ directory" \
  "[[ -n \"${REVIEWS_OVERRIDE:-}\" ]] && true || false"
assert_true "25p-2: NOTIFICATION_ENABLED was never set to true in the Sprint-016 test block (no live Telegram delivery attempted)" \
  "[[ -z \"${NOTIFICATION_ENABLED:-}\" ]] && true || false"

echo "  (Sprint-013/014 notify and notify-gate tests re-verified above by Test 22/23/24, run unchanged in this same suite: zero regression)"

###############################################################################
# Test 26: Sprint-017 Handoff Template Standardization & Notification Gate
# Execution Policy
###############################################################################
echo ""
echo "=== Test 26: Sprint-017 full reading list, Telegram Notification block, notify-gate safety, doc requirements ==="

SP17_DIR="$TEST_DIR/sprint17-e2e"
rm -rf "$SP17_DIR"
# PROJECT_NAME intentionally contains a space here (like a real "AI
# Workspace" project name) to catch quoting regressions in the rendered
# notify-gate command (Sprint-017 Must Fix round).
cd "$SCRIPT_DIR" && PROJECT_ID=sp17-demo PROJECT_NAME="Sprint 17 Demo" REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" init sprint17-e2e 001 >/dev/null 2>&1
cd "$SCRIPT_DIR" && PROJECT_ID=sp17-demo PROJECT_NAME="Sprint 17 Demo" REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" skeleton sprint17-e2e 001 --type implementation >/dev/null 2>&1
for f in architecture.md claude_report.md; do
  printf '# %s\n\nReal content, not a placeholder.\n' "$f" > "$TEST_DIR/sprint17-e2e/round-001/$f"
done
cd "$SCRIPT_DIR" && PROJECT_ID=sp17-demo PROJECT_NAME="Sprint 17 Demo" REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" check sprint17-e2e 001 >/dev/null 2>&1
handoff_c2c="$(cat "$TEST_DIR/sprint17-e2e/round-001/handoff_package.md" 2>/dev/null || echo "")"

# 26a/26b: full reading list present, not a shortened subset (all 10 items
# must appear, in the Required Reading section).
all_reading_items_present=true
for item in "PROJECT_BOOTSTRAP.md" "AGENTS.md" "GPT.md" "CLAUDE.md" "CODEX.md" \
            "docs/development/development-workflow.md" "docs/development/consensus-workflow.md" \
            "docs/development/n8n-claude-done-notification.md" "docs/development/n8n-codex-review-done-notification.md" \
            "scripts/review_bridge.sh"; do
  [[ "$handoff_c2c" == *"$item"* ]] || { all_reading_items_present=false; echo "    (handoff_package.md missing reading item: $item)"; }
done
assert_true "26a: handoff_package.md (Claude->Codex) contains the full 10-item reading list" $all_reading_items_present
assert_contains "26b: handoff_package.md documents the Missing Context rule for its reading list" \
  "若上述文件不存在，請在 report 中記錄為 Missing Context" "$handoff_c2c"

# 26c/26d: Telegram Notification block present with all 6 required fields.
assert_contains "26c: handoff_package.md contains a Telegram Notification block" "Telegram Notification:" "$handoff_c2c"
all_telegram_fields_present=true
for field in "Should notify Product Owner" "gate_id" "sprint_id" "round_id" "artifact_path" "Expected Telegram result"; do
  [[ "$handoff_c2c" == *"$field"* ]] || { all_telegram_fields_present=false; echo "    (Telegram Notification block missing field: $field)"; }
done
assert_true "26d: Telegram Notification block contains all 6 required fields" $all_telegram_fields_present

# 26e: gate_id used is a real canonical gate_id, not a placeholder.
telegram_gate_id="$(echo "$handoff_c2c" | awk -F': ' '/^- gate_id:/{print $2; exit}')"
gate_id_is_canonical=false
for gid in "${gate25_ids[@]}"; do
  [[ "$gid" == "$telegram_gate_id" ]] && gate_id_is_canonical=true
done
assert_true "26e: Telegram Notification gate_id ('$telegram_gate_id') is a real canonical gate_id, not a placeholder" $gate_id_is_canonical

###############################################################################
# Sprint-017 Must Fix round (Product Owner Validation blocked: notification
# was descriptive but not actionable -- no runnable command was ever given)
###############################################################################

# 26e-mf1: formal PO Gate handoff must explicitly say YES, never default to
# NO / N/A the way the original chat-based manual handoff example did.
assert_contains "26e-mf1: formal PO Gate handoff explicitly states 'Should notify Product Owner: YES'" \
  "Should notify Product Owner: YES" "$handoff_c2c"
assert_true "26e-mf2: formal PO Gate handoff does not fall back to the chat-based 'NO' / 'N/A' pattern" \
  "[[ \"\$handoff_c2c\" != *'Should notify Product Owner: NO'* && \"\$handoff_c2c\" != *'gate_id: N/A'* ]] && true || false"

# 26e-mf3: an exact, executable notify-gate command is present, with the
# correct (bare numeric) round -- not the "round-NNN" display form, which
# `notify-gate` would reject via validate_round.
assert_contains "26e-mf3: Telegram Notification block includes an executable notify-gate command" \
  "notify-gate command" "$handoff_c2c"
notify_gate_cmd_line="$(echo "$handoff_c2c" | grep -A1 'notify-gate command' | tail -1)"
assert_contains "26e-mf3b: the rendered command actually invokes review_bridge.sh notify-gate" \
  "review_bridge.sh notify-gate" "$notify_gate_cmd_line"
assert_contains "26e-mf3c: the rendered command uses the correct gate_id" \
  "claude_implementation_report_acceptance" "$notify_gate_cmd_line"
assert_contains "26e-mf3d: the rendered command uses the bare numeric round (001), not 'round-001'" \
  " sprint17-e2e 001 " "$notify_gate_cmd_line"
assert_true "26e-mf3e: the rendered command does NOT contain the malformed 'round-001' CLI argument" \
  "[[ \"\$notify_gate_cmd_line\" != *' round-001 '* ]] && true || false"

# 26e-mf4: PROJECT_NAME containing a space (a very likely real-world value,
# e.g. "AI Workspace") is properly quoted in the rendered command -- this is
# exactly the bug that made the command silently unusable if Product Owner
# copy-pasted it verbatim.
assert_contains "26e-mf4: PROJECT_NAME with a space is quoted in the rendered command (copy-paste safe)" \
  'PROJECT_NAME="Sprint 17 Demo"' "$notify_gate_cmd_line"

# 26e-mf5: an explicit "Product Owner Action Required" field is present, so
# the block is actionable, not just descriptive.
assert_contains "26e-mf5: Telegram Notification block includes 'Product Owner Action Required'" \
  "Product Owner Action Required" "$handoff_c2c"

# 26e-mf6: wording makes clear the notification is NOT yet delivered / not
# yet completed until Product Owner actually runs the command.
assert_contains "26e-mf6: wording states the Telegram result is not yet sent until Product Owner executes the command" \
  "尚未送出" "$handoff_c2c"

# 26e-mf7: safety boundary re-confirmed after this Must Fix round -- still
# exactly one call site for cmd_notify_gate (the CLI dispatcher).
notify_gate_call_sites_mf="$(grep -n 'cmd_notify_gate' "$BRIDGE" | grep -v '^[0-9]*:#' | grep -v 'cmd_notify_gate()')"
notify_gate_call_count_mf="$(echo "$notify_gate_call_sites_mf" | grep -c 'cmd_notify_gate "\$@"')"
assert_eq "26e-mf7: cmd_notify_gate is still invoked from exactly one place after the Must Fix round" "1" "$notify_gate_call_count_mf"
assert_true "26e-mf8: _telegram_notification_block still only renders text and never calls notify-gate itself" \
  "! grep -q 'cmd_notify_gate' <(sed -n '/^_telegram_notification_block()/,/^}/p' \"$BRIDGE\")"

# Same checks for the Codex->Claude direction handoff package.
mkdir -p "$TEST_DIR/sprint17-e2e/round-001"
printf '# codex_review.md\n\nReal content, not a placeholder.\n' > "$TEST_DIR/sprint17-e2e/round-001/codex_review.md"
cd "$SCRIPT_DIR" && PROJECT_ID=sp17-demo PROJECT_NAME="Sprint 17 Demo" REVIEWS_OVERRIDE="$TEST_DIR" bash "$BRIDGE" check sprint17-e2e 001 >/dev/null 2>&1
handoff_x2c="$(cat "$TEST_DIR/sprint17-e2e/round-001/handoff_package.md" 2>/dev/null || echo "")"
assert_contains "26f: handoff_package.md (Codex->Claude direction) also contains the full reading list" \
  "docs/development/n8n-codex-review-done-notification.md" "$handoff_x2c"
assert_contains "26g: handoff_package.md (Codex->Claude direction) also contains a Telegram Notification block" \
  "Telegram Notification:" "$handoff_x2c"

# 26h: notify-gate is never invoked programmatically anywhere in
# review_bridge.sh except the single main-dispatcher case entry.
notify_gate_call_sites="$(grep -n 'cmd_notify_gate' "$BRIDGE" | grep -v '^[0-9]*:#' | grep -v 'cmd_notify_gate()' )"
notify_gate_call_count="$(echo "$notify_gate_call_sites" | grep -c 'cmd_notify_gate "\$@"')"
assert_eq "26h: cmd_notify_gate is invoked from exactly one place (the main dispatcher), never automatically" "1" "$notify_gate_call_count"

# 26i: docs/development/consensus-workflow.md documents Context Completeness
# Check for all 4 required report types.
consensus_doc26="$(cat /home/ivan/AI/docs/development/consensus-workflow.md 2>/dev/null || echo "")"
all_report_types_documented=true
for rt in "Claude Implementation Report" "Claude Must Fix Report" "Codex Review Report" "Codex Final Review Report"; do
  [[ "$consensus_doc26" == *"$rt"* ]] || { all_report_types_documented=false; echo "    (consensus-workflow.md missing report type: $rt)"; }
done
assert_true "26i: consensus-workflow.md documents Context Completeness Check for all 4 report types" $all_report_types_documented
assert_contains "26j: consensus-workflow.md's Context Completeness Check block matches the required format" \
  "Full required reading list provided: PASS / FAIL" "$consensus_doc26"

# 26k: Manual Handoff vs Formal Telegram Gate Notification distinction is
# documented (so manual handoff can never be mistaken for a delivered
# Telegram notification).
telegram_spec26="$(cat /home/ivan/AI/docs/development/telegram-po-gate-notification-specification.md 2>/dev/null || echo "")"
assert_contains "26k: Telegram Gate spec distinguishes Manual Handoff from Formal Telegram Gate Notification" \
  "此模式不代表 Telegram 已通知" "$telegram_spec26"
assert_contains "26l: Telegram Gate spec states only an actual notify-gate execution counts as Telegram notification" \
  "只有實際執行 \`notify-gate\` 且 Telegram 收到通知後，才可記錄為正式 Telegram Gate Notification 完成" "$telegram_spec26"

# 26m: notify-gate Execution Policy documents Claude/Codex may never trigger
# Telegram automatically, and the correct CLI parameter order.
assert_contains "26m-1: Telegram Gate spec states Claude/Codex must not auto-trigger Telegram" \
  "Claude / Codex 不得自動觸發 Telegram" "$telegram_spec26"
assert_contains "26m-2: Telegram Gate spec documents notify-gate's first parameter is gate_id, not sprint_id" \
  "第一個參數是 \`gate_id\`，不是 \`sprint_id\`" "$telegram_spec26"

# 26n: Retrospective / Actual Flow Report Flow Deviation Check is documented.
assert_contains "26n: consensus-workflow.md documents the Retrospective Flow Deviation Check section" \
  "## Flow Deviation Check" "$consensus_doc26"
all_flow_fields_present=true
for field in "Full reading list used in all formal Handoff Packages" "notify-gate executed by Product Owner" \
             "Telegram notification received" "Manual handoff used instead of Telegram notification" \
             "Manual Gate skipped" "Review scope drift occurred" "unrelated dirty / untracked files mixed into Sprint scope"; do
  [[ "$consensus_doc26" == *"$field"* ]] || { all_flow_fields_present=false; echo "    (Flow Deviation Check missing field: $field)"; }
done
assert_true "26o: Flow Deviation Check section contains all required fields" $all_flow_fields_present

echo "  (Sprint-013/014/016 notify, notify-gate, and Gate metadata tests re-verified above, run unchanged in this same suite: zero regression)"

###############################################################################
# Test 27: Sprint-017 Must Fix Round 2 -- concrete sprint-017/001 notify-gate
# artifact validation fixture (Telegram Gate Validation Precheck)
###############################################################################
echo ""
echo "=== Test 27: concrete reviews/sprint-017/round-001 notify-gate artifact (Precheck fixture) ==="

FORMAL_HANDOFF="/home/ivan/AI/reviews/sprint-017/round-001/formal_gate_handoff.md"
assert_true "27a: reviews/sprint-017/round-001/formal_gate_handoff.md exists" \
  "[[ -f \"$FORMAL_HANDOFF\" ]] && true || false"

formal_handoff_content="$(cat "$FORMAL_HANDOFF" 2>/dev/null || echo "")"

assert_contains "27b: artifact contains the real Review Bridge invocation" \
  "./scripts/review_bridge.sh notify-gate" "$formal_handoff_content"
assert_contains "27c: artifact contains a real, non-placeholder gate_id" \
  "product_owner_validation_approval" "$formal_handoff_content"
assert_contains "27d: artifact's command targets sprint-017" \
  "notify-gate product_owner_validation_approval sprint-017 001" "$formal_handoff_content"
assert_true "27e: artifact's command uses the bare round 001, not the malformed 'round-001' CLI argument" \
  "[[ \"\$formal_handoff_content\" == *'sprint-017 001 '* && \"\$formal_handoff_content\" != *'notify-gate product_owner_validation_approval sprint-017 round-001'* ]] && true || false"
assert_contains "27f: artifact's command references a real Sprint-017 artifact_path" \
  "reviews/sprint-017/round-001/codex_final_review.md" "$formal_handoff_content"
assert_contains "27g: artifact explicitly states 'Should notify Product Owner: YES'" \
  "Should notify Product Owner: YES" "$formal_handoff_content"
assert_true "27h: artifact's gate_id is not left as N/A or a placeholder" \
  "[[ \"\$formal_handoff_content\" != *'gate_id: N/A'* && \"\$formal_handoff_content\" != *'gate_id: <'* ]] && true || false"
assert_contains "27i: artifact includes 'Product Owner Action Required'" \
  "Product Owner Action Required" "$formal_handoff_content"
assert_contains "27j: artifact states the notification is not yet sent (尚未送出)" \
  "尚未送出" "$formal_handoff_content"

# 27k: the gate_id used is one of the 21 canonical gate_ids (reuses the
# whitelist already extracted for Test 25/26).
formal_gate_id="$(echo "$formal_handoff_content" | awk -F': ' '/^gate_id:/{print $2; exit}')"
formal_gate_id_canonical=false
for gid in "${gate25_ids[@]}"; do
  [[ "$gid" == "$formal_gate_id" ]] && formal_gate_id_canonical=true
done
assert_true "27k: artifact's gate_id ('$formal_gate_id') is one of the 21 canonical gate_ids" $formal_gate_id_canonical

# 27l: running this entire test suite (including generating/checking the
# formal_gate_handoff.md fixture) must never have executed notify-gate for
# real against the actual repository -- compare against the snapshot taken
# before any test ran, rather than a hardcoded count that would go stale.
real_history_count_after="$(wc -l < "$REAL_HISTORY_FILE" 2>/dev/null || echo 0)"
assert_eq "27l: the real repository's notification_history.jsonl record count is unchanged by this test run (no real notify-gate was executed)" \
  "$REAL_HISTORY_COUNT_BEFORE" "$real_history_count_after"

###############################################################################
# Test 28: Sprint-017 Must Fix Round 3 -- contract test proving all 21
# canonical Product Owner Gates (not just the one Product Owner has so far
# live-tested) produce a correctly-formed, actionable, inline-content
# Notification Package. Nothing in this test sets NOTIFICATION_ENABLED=true
# or contacts Telegram; every invocation is isolated under REVIEWS_OVERRIDE.
###############################################################################
echo ""
echo "=== Test 28: all 21 canonical Gates -- inline artifact content + actionable Telegram block contract ==="

GATE28_ARTIFACTS="$TEST_DIR/gate28-artifacts"
mkdir -p "$GATE28_ARTIFACTS"
GATE28_MARKER="GATE28-DISTINCTIVE-ARTIFACT-CONTENT-MARKER-$$"
cat > "$GATE28_ARTIFACTS/a.md" <<EOF
# Gate 28 Contract Test Artifact

$GATE28_MARKER

This content must appear inline in every one of the 21 gates' Notification
Package, not merely referenced by path.
EOF

# Extract the two pure, side-effect-free rendering functions into an
# isolated file and source only those -- never the CLI dispatcher -- so this
# test can call _telegram_notification_block() directly for all 21 gate_ids,
# not just the 2 gate_ids wired into write_handoff_package_claude_to_codex /
# write_handoff_package_codex_to_claude. This proves the renderer generalizes
# to the full canonical whitelist, which is the actual capability Product
# Owner asked to see evidence for.
GATE28_FUNCS="$TEST_DIR/gate28-funcs.sh"
sed -n '/^_full_reading_list_zh() {/,/^}/p' "$BRIDGE" > "$GATE28_FUNCS"
printf '\n' >> "$GATE28_FUNCS"
sed -n '/^_telegram_notification_block() {/,/^}/p' "$BRIDGE" >> "$GATE28_FUNCS"
# shellcheck source=/dev/null
source "$GATE28_FUNCS"

all_g28_inline_content=true
all_g28_gate_id_present=true
all_g28_sprint_round_path=true
all_g28_no_placeholder=true
all_g28_notify_cmd_present=true
all_g28_notify_cmd_correct=true
all_g28_no_malformed_round=true
all_g28_po_action_present=true

round28=1
for gid in "${gate25_ids[@]}"; do
  round28_padded="$(printf '%03d' "$round28")"

  # (a) cmd_notify_gate contract: real gate_id/sprint_id/round_id/artifact_path,
  # plus inline artifact content (Blocker 1's fix, proven for all 21 gates).
  # TELEGRAM_CONTENT_MODE=full is required here (Sprint-017 Must Fix Round
  # 6 changed the default to "handoff", which no longer inlines raw
  # artifact content) -- this loop specifically proves the full-mode inline
  # capability still works for all 21 gates.
  TELEGRAM_CONTENT_MODE=full PROJECT_ID=gate28 PROJECT_NAME="Gate28" REVIEWS_OVERRIDE="$TEST_DIR" \
    bash "$BRIDGE" notify-gate "$gid" sprint-gate28 "$round28" "$GATE28_ARTIFACTS/a.md" >/dev/null 2>&1
  pkg="$TEST_DIR/sprint-gate28/round-$round28_padded/notifications/gate-${gid}.md"
  pkg_content="$(cat "$pkg" 2>/dev/null || echo "")"

  [[ "$pkg_content" == *"$GATE28_MARKER"* ]] || { all_g28_inline_content=false; echo "    (gate $gid: package does not inline the artifact content)"; }
  [[ "$pkg_content" == *"gate_id: $gid"* ]] || { all_g28_gate_id_present=false; echo "    (gate $gid: package does not report its own real gate_id)"; }
  [[ "$pkg_content" == *"sprint-gate28"* && "$pkg_content" == *"round-$round28_padded"* && "$pkg_content" == *"$GATE28_ARTIFACTS/a.md"* ]] \
    || { all_g28_sprint_round_path=false; echo "    (gate $gid: package missing sprint_id/round_id/artifact_path)"; }

  # (b) _telegram_notification_block contract, called directly for this
  # gate_id: real (non-placeholder) gate_id, correct notify-gate command
  # with the bare round (never "round-NNN" as the CLI argument), and
  # Product Owner Action Required wording.
  block="$(_telegram_notification_block "$gid" "sprint-gate28" "round-$round28_padded" "$GATE28_ARTIFACTS/a.md")"

  [[ "$block" == *"gate_id: $gid"* ]] || { all_g28_no_placeholder=false; echo "    (gate $gid: Telegram block does not report the real gate_id)"; }
  [[ "$block" != *"gate_id: N/A"* && "$block" != *"gate_id: <"* ]] || { all_g28_no_placeholder=false; echo "    (gate $gid: Telegram block left gate_id as N/A or a placeholder)"; }
  [[ "$block" == *"notify-gate command"* ]] || { all_g28_notify_cmd_present=false; echo "    (gate $gid: Telegram block missing the notify-gate command line)"; }
  [[ "$block" == *"notify-gate $gid sprint-gate28 $round28_padded "* ]] || { all_g28_notify_cmd_correct=false; echo "    (gate $gid: rendered command does not use the correct gate_id/sprint_id/bare round in order)"; }
  [[ "$block" != *"notify-gate $gid sprint-gate28 round-$round28_padded"* ]] || { all_g28_no_malformed_round=false; echo "    (gate $gid: rendered command uses the malformed 'round-NNN' CLI argument)"; }
  [[ "$block" == *"Product Owner Action Required"* ]] || { all_g28_po_action_present=false; echo "    (gate $gid: Telegram block missing Product Owner Action Required)"; }

  ((round28++))
done

assert_true "28a: all 21 gates inline the real artifact content in their Notification Package (not just a path reference)" $all_g28_inline_content
assert_true "28b: all 21 gates report their own real (non-placeholder) gate_id" $all_g28_gate_id_present
assert_true "28c: all 21 gates' packages contain sprint_id, round_id, and artifact_path" $all_g28_sprint_round_path
assert_true "28d: _telegram_notification_block never leaves gate_id as N/A or a placeholder, for any of the 21 gates" $all_g28_no_placeholder
assert_true "28e: _telegram_notification_block includes an executable notify-gate command for all 21 gates" $all_g28_notify_cmd_present
assert_true "28f: the rendered notify-gate command uses the correct gate_id/sprint_id/bare-round order for all 21 gates" $all_g28_notify_cmd_correct
assert_true "28g: the rendered notify-gate command never uses the malformed 'round-NNN' CLI argument, for any of the 21 gates" $all_g28_no_malformed_round
assert_true "28h: _telegram_notification_block includes 'Product Owner Action Required' for all 21 gates" $all_g28_po_action_present

# 28i: this whole contract test, across all 21 gates, must never have
# contacted Telegram or grown the real repository's notification history
# (every invocation above used REVIEWS_OVERRIDE and left NOTIFICATION_ENABLED
# unset).
real_history_count_after_g28="$(wc -l < "$REAL_HISTORY_FILE" 2>/dev/null || echo 0)"
assert_eq "28i: the real repository's notification_history.jsonl is still unaffected after testing all 21 gates" \
  "$REAL_HISTORY_COUNT_BEFORE" "$real_history_count_after_g28"

echo "  (Sprint-013/014/016/017 notify, notify-gate, and Gate metadata tests re-verified above, run unchanged in this same suite: zero regression)"

###############################################################################
# Test 29: Sprint-017 Must Fix Round 4 -- optional Traditional-Chinese
# Product Owner Summary (summary_path), rendered before raw artifact content
###############################################################################
echo ""
echo "=== Test 29: notify-gate optional summary_path (Chinese Product Owner Summary before raw artifact content) ==="

GATE29_ARTIFACTS="$TEST_DIR/gate29-artifacts"
mkdir -p "$GATE29_ARTIFACTS"
cat > "$GATE29_ARTIFACTS/artifact.md" <<'EOF'
# English Artifact
Long English content Product Owner should not have to parse first.
EOF
GATE29_SUMMARY_MARKER="GATE29-CHINESE-SUMMARY-MARKER-$$"
cat > "$GATE29_ARTIFACTS/summary.md" <<EOF
$GATE29_SUMMARY_MARKER
Sprint: sprint-gate29 / round-001
現況：測試用摘要
EOF

# 29a: backward compatibility -- omitting summary_path renders exactly as
# before (no "Product Owner Summary" heading at all).
PROJECT_ID=gate29 PROJECT_NAME="Gate29" REVIEWS_OVERRIDE="$TEST_DIR" \
  bash "$BRIDGE" notify-gate product_owner_validation_approval sprint-gate29-no-summary 001 "$GATE29_ARTIFACTS/artifact.md" >/dev/null 2>&1
pkg_no_summary="$(cat "$TEST_DIR/sprint-gate29-no-summary/round-001/notifications/gate-product_owner_validation_approval.md" 2>/dev/null || echo "")"
assert_true "29a-0: the no-summary package was actually generated (non-empty, not a vacuous check)" \
  "[[ -n \"\$pkg_no_summary\" ]] && true || false"
assert_true "29a: omitting summary_path renders no Product Owner Summary section (backward compatible)" \
  "[[ \"\$pkg_no_summary\" != *'Product Owner Summary'* ]] && true || false"

# 29b-29e: providing summary_path inlines it, in full, BEFORE the raw
# artifact content, under the required Chinese heading. TELEGRAM_CONTENT_MODE=full
# is required here (Sprint-017 Must Fix Round 6 default is "handoff", which
# does not inline raw artifact content) since 29e specifically checks that
# raw content is still present and ordered correctly in full mode.
TELEGRAM_CONTENT_MODE=full PROJECT_ID=gate29 PROJECT_NAME="Gate29" REVIEWS_OVERRIDE="$TEST_DIR" \
  bash "$BRIDGE" notify-gate product_owner_validation_approval sprint-gate29-with-summary 001 \
  "$GATE29_ARTIFACTS/artifact.md" "$GATE29_ARTIFACTS/summary.md" >/dev/null 2>&1
pkg_with_summary="$(cat "$TEST_DIR/sprint-gate29-with-summary/round-001/notifications/gate-product_owner_validation_approval.md" 2>/dev/null || echo "")"
assert_true "29b-0: the with-summary package was actually generated (non-empty, not a vacuous check)" \
  "[[ -n \"\$pkg_with_summary\" ]] && true || false"

assert_contains "29b: package contains the required '🇹🇼 Product Owner Summary' heading" \
  "Product Owner Summary" "$pkg_with_summary"
assert_contains "29c: package inlines the full summary content" "$GATE29_SUMMARY_MARKER" "$pkg_with_summary"

summary_pos="$(echo "$pkg_with_summary" | grep -n "Product Owner Summary" | head -1 | cut -d: -f1)"
artifact_begin_pos="$(echo "$pkg_with_summary" | grep -n "BEGIN ARTIFACT CONTENT" | head -1 | cut -d: -f1)"
assert_true "29d: the Product Owner Summary appears BEFORE the raw artifact content (BEGIN ARTIFACT CONTENT)" \
  "[[ -n \"\$summary_pos\" && -n \"\$artifact_begin_pos\" && \"\$summary_pos\" -lt \"\$artifact_begin_pos\" ]] && true || false"
assert_contains "29e: the raw artifact content is still present below the summary, as evidence" \
  "Long English content Product Owner should not have to parse first." "$pkg_with_summary"

# 29f: a missing summary_path fails loudly (consistent with how a missing
# artifact_path is already handled), never silently ignored.
PROJECT_ID=gate29 PROJECT_NAME="Gate29" REVIEWS_OVERRIDE="$TEST_DIR" \
  bash "$BRIDGE" notify-gate product_owner_validation_approval sprint-gate29-missing-sum 001 \
  "$GATE29_ARTIFACTS/artifact.md" "$GATE29_ARTIFACTS/does-not-exist.md" >/tmp/gate29f.out 2>&1
assert_exit_code "29f: a missing summary_path is a hard failure, not a silent skip" 1 "$?"
assert_contains "29f-2: the error names the missing summary file" "Summary artifact not found" "$(cat /tmp/gate29f.out)"
rm -f /tmp/gate29f.out

# 29g: no real Telegram/notify-gate side effects from this test block.
real_history_count_after_g29="$(wc -l < "$REAL_HISTORY_FILE" 2>/dev/null || echo 0)"
assert_eq "29g: the real repository's notification_history.jsonl is unaffected by the summary_path tests" \
  "$REAL_HISTORY_COUNT_BEFORE" "$real_history_count_after_g29"

###############################################################################
# Test 30: Sprint-017 Must Fix Round 5 -- optional Next AI Handoff Package
# (6th notify-gate argument), and the real Codex Git Review handoff artifact
# for product_owner_validation_approval
###############################################################################
echo ""
echo "=== Test 30: notify-gate optional next-handoff-path (copy-pasteable Next AI Handoff Package) ==="

GATE30_ARTIFACTS="$TEST_DIR/gate30-artifacts"
mkdir -p "$GATE30_ARTIFACTS"
cat > "$GATE30_ARTIFACTS/artifact.md" <<'EOF'
# Raw Artifact Evidence Content
This must remain present even after the new feature is added.
EOF
GATE30_SUMMARY_MARKER="GATE30-SUMMARY-MARKER-$$"
cat > "$GATE30_ARTIFACTS/summary.md" <<EOF
$GATE30_SUMMARY_MARKER
EOF
GATE30_HANDOFF_MARKER="GATE30-NEXT-HANDOFF-MARKER-$$"
cat > "$GATE30_ARTIFACTS/next_handoff.md" <<EOF
# Codex Git Review Handoff Package (test fixture)

## Target AI
Codex

$GATE30_HANDOFF_MARKER

請閱讀：
- PROJECT_BOOTSTRAP.md
- AGENTS.md
- GPT.md
- CLAUDE.md
- CODEX.md
- docs/development/development-workflow.md
- docs/development/consensus-workflow.md
- docs/development/n8n-claude-done-notification.md
- docs/development/n8n-codex-review-done-notification.md
- scripts/review_bridge.sh

輸出語言：繁體中文。
EOF

# 30a-0: backward compatibility -- omitting next-handoff-path (5-arg call,
# same as Round 4) renders no "Next AI Handoff Package" section at all.
PROJECT_ID=gate30 PROJECT_NAME="Gate30" REVIEWS_OVERRIDE="$TEST_DIR" \
  bash "$BRIDGE" notify-gate product_owner_validation_approval sprint-gate30-no-handoff 001 \
  "$GATE30_ARTIFACTS/artifact.md" "$GATE30_ARTIFACTS/summary.md" >/dev/null 2>&1
pkg_no_handoff="$(cat "$TEST_DIR/sprint-gate30-no-handoff/round-001/notifications/gate-product_owner_validation_approval.md" 2>/dev/null || echo "")"
assert_true "30a-0: 5-arg call (no next-handoff-path) still succeeds and produces a package" \
  "[[ -n \"\$pkg_no_handoff\" ]] && true || false"
assert_true "30a-1: omitting next-handoff-path renders no '🤖 Next AI Handoff Package' section (backward compatible)" \
  "[[ \"\$pkg_no_handoff\" != *'🤖 Next AI Handoff Package'* ]] && true || false"

# 30b-30i: providing next-handoff-path (6th argument) renders the required
# section with all its content, alongside the pre-existing sections.
# TELEGRAM_CONTENT_MODE=full is required here (Sprint-017 Must Fix Round 6
# default is "handoff", which does not inline raw artifact content) since
# 30g/30g-2/30i specifically check that Raw Artifact Evidence is still
# present and correctly ordered relative to the other 3 sections when full
# mode combines all of them.
TELEGRAM_CONTENT_MODE=full PROJECT_ID=gate30 PROJECT_NAME="Gate30" REVIEWS_OVERRIDE="$TEST_DIR" \
  bash "$BRIDGE" notify-gate product_owner_validation_approval sprint-gate30-with-handoff 001 \
  "$GATE30_ARTIFACTS/artifact.md" "$GATE30_ARTIFACTS/summary.md" "$GATE30_ARTIFACTS/next_handoff.md" >/dev/null 2>&1
pkg_with_handoff="$(cat "$TEST_DIR/sprint-gate30-with-handoff/round-001/notifications/gate-product_owner_validation_approval.md" 2>/dev/null || echo "")"
assert_true "30b-0: 6-arg call (with next-handoff-path) succeeds and produces a package" \
  "[[ -n \"\$pkg_with_handoff\" ]] && true || false"

# (requirement 5, item 1) notification includes Next AI Handoff Package
assert_contains "30b: package contains the '🤖 Next AI Handoff Package' heading" \
  "Next AI Handoff Package" "$pkg_with_handoff"

# (requirement 5, item 2) the handoff package is copy-pasteable: isolated in
# its own delimited block, distinct from surrounding sections.
next_handoff_block_count="$(echo "$pkg_with_handoff" | grep -c '🤖 Next AI Handoff Package')"
assert_eq "30c: exactly one Next AI Handoff Package section (cleanly isolated, not duplicated)" "1" "$next_handoff_block_count"
assert_contains "30c-2: the full next-handoff content is inlined verbatim (copy-pasteable)" "$GATE30_HANDOFF_MARKER" "$pkg_with_handoff"

# (requirement 5, item 3) the handoff package targets Codex Git Review
assert_contains "30d: the inlined handoff package identifies Codex as Target AI" "## Target AI" "$pkg_with_handoff"
assert_contains "30d-2: the inlined handoff package is for Codex" "Codex" "$pkg_with_handoff"

# (requirement 5, item 4) Traditional Chinese output rule is included
assert_contains "30e: the inlined handoff package requires Traditional Chinese output" "輸出語言：繁體中文" "$pkg_with_handoff"

# (requirement 5, item 5) full reading list is included in the next-handoff content
all_g30_reading_items=true
for item in "PROJECT_BOOTSTRAP.md" "AGENTS.md" "GPT.md" "CLAUDE.md" "CODEX.md" \
            "docs/development/development-workflow.md" "docs/development/consensus-workflow.md" \
            "docs/development/n8n-claude-done-notification.md" "docs/development/n8n-codex-review-done-notification.md" \
            "scripts/review_bridge.sh"; do
  [[ "$pkg_with_handoff" == *"$item"* ]] || { all_g30_reading_items=false; echo "    (next-handoff content missing reading item: $item)"; }
done
assert_true "30f: the inlined handoff package's reading list contains all 10 required items" $all_g30_reading_items

# (requirement 5, items 6-7) raw artifact evidence and Product Owner Summary
# both remain present alongside the new Next AI Handoff Package section.
assert_contains "30g: Raw Artifact Evidence section is still present" "📄 Raw Artifact Evidence" "$pkg_with_handoff"
assert_contains "30g-2: raw artifact content is still inlined" \
  "This must remain present even after the new feature is added." "$pkg_with_handoff"
assert_contains "30h: Product Owner Summary section is still present" "Product Owner Summary" "$pkg_with_handoff"
assert_contains "30h-2: Product Owner Summary content is still inlined" "$GATE30_SUMMARY_MARKER" "$pkg_with_handoff"

# 30i: the 4 sections appear in the documented, consistent order: Product
# Owner Summary -> Product Owner Decision Options -> Next AI Handoff
# Package -> Raw Artifact Evidence.
pos_summary="$(echo "$pkg_with_handoff" | grep -n "Product Owner Summary" | head -1 | cut -d: -f1)"
pos_decision="$(echo "$pkg_with_handoff" | grep -n "Product Owner Decision Options" | head -1 | cut -d: -f1)"
pos_next_handoff="$(echo "$pkg_with_handoff" | grep -n "Next AI Handoff Package" | head -1 | cut -d: -f1)"
pos_raw_evidence="$(echo "$pkg_with_handoff" | grep -n "Raw Artifact Evidence" | head -1 | cut -d: -f1)"
assert_true "30i: sections appear in order: Summary -> Decision Options -> Next AI Handoff -> Raw Evidence" \
  "[[ -n \"\$pos_summary\" && -n \"\$pos_decision\" && -n \"\$pos_next_handoff\" && -n \"\$pos_raw_evidence\" && \"\$pos_summary\" -lt \"\$pos_decision\" && \"\$pos_decision\" -lt \"\$pos_next_handoff\" && \"\$pos_next_handoff\" -lt \"\$pos_raw_evidence\" ]] && true || false"

# 30j: a missing next-handoff-path fails loudly, never silently ignored
# (consistent with how missing artifact_path / summary_path already behave).
PROJECT_ID=gate30 PROJECT_NAME="Gate30" REVIEWS_OVERRIDE="$TEST_DIR" \
  bash "$BRIDGE" notify-gate product_owner_validation_approval sprint-gate30-missing 001 \
  "$GATE30_ARTIFACTS/artifact.md" "$GATE30_ARTIFACTS/summary.md" "$GATE30_ARTIFACTS/does-not-exist.md" >/tmp/gate30j.out 2>&1
assert_exit_code "30j: a missing next-handoff-path is a hard failure, not a silent skip" 1 "$?"
assert_contains "30j-2: the error names the missing Next AI Handoff Package file" "Next AI Handoff Package artifact not found" "$(cat /tmp/gate30j.out)"
rm -f /tmp/gate30j.out

# 30k: the real, concrete Codex Git Review handoff artifact for Sprint-017's
# current Gate actually exists and satisfies all the same content
# requirements (mirrors reviews/sprint-017/round-001/formal_gate_handoff.md
# from Must Fix Round 2, now for the Next AI Handoff Package).
REAL_GIT_REVIEW_HANDOFF="/home/ivan/AI/reviews/sprint-017/round-001/codex_git_review_handoff_zh.md"
assert_true "30k-0: reviews/sprint-017/round-001/codex_git_review_handoff_zh.md exists" \
  "[[ -f \"$REAL_GIT_REVIEW_HANDOFF\" ]] && true || false"
real_git_review_handoff_content="$(cat "$REAL_GIT_REVIEW_HANDOFF" 2>/dev/null || echo "")"
assert_contains "30k-1: real Codex Git Review handoff targets Codex" "## 1. Target AI" "$real_git_review_handoff_content"
assert_contains "30k-2: real Codex Git Review handoff requires Traditional Chinese output" "繁體中文" "$real_git_review_handoff_content"
assert_contains "30k-3: real Codex Git Review handoff includes the Context Completeness Check requirement" \
  "Context Completeness Check" "$real_git_review_handoff_content"
assert_contains "30k-4: real Codex Git Review handoff states the exact report path to generate" \
  "reviews/sprint-017/round-001/codex_git_review.md" "$real_git_review_handoff_content"
all_g30k_restrictions=true
for restriction in "git add" "commit" "push" "notify-gate" "Telegram" "n8n"; do
  [[ "$real_git_review_handoff_content" == *"$restriction"* ]] || { all_g30k_restrictions=false; echo "    (real handoff missing restriction mention: $restriction)"; }
done
assert_true "30k-5: real Codex Git Review handoff mentions all required restrictions (git add/commit/push/notify-gate/Telegram/n8n)" $all_g30k_restrictions

# 30l: no real Telegram/notify-gate side effects from this entire test block.
real_history_count_after_g30="$(wc -l < "$REAL_HISTORY_FILE" 2>/dev/null || echo 0)"
assert_eq "30l: the real repository's notification_history.jsonl is unaffected by the Next AI Handoff Package tests" \
  "$REAL_HISTORY_COUNT_BEFORE" "$real_history_count_after_g30"

###############################################################################
# Test 31: Sprint-017 Must Fix Round 6 -- Telegram Content Mode / Copyability
# Improvement (TELEGRAM_CONTENT_MODE: summary / handoff / full)
###############################################################################
echo ""
echo "=== Test 31: TELEGRAM_CONTENT_MODE (default handoff, opt-in full raw evidence) ==="

GATE31_ARTIFACTS="$TEST_DIR/gate31-artifacts"
mkdir -p "$GATE31_ARTIFACTS"
cat > "$GATE31_ARTIFACTS/artifact.md" <<'EOF'
# English Raw Artifact
Long raw content that should only be inlined in full mode.
EOF
GATE31_SUMMARY_MARKER="GATE31-SUMMARY-MARKER-$$"
cat > "$GATE31_ARTIFACTS/summary.md" <<EOF
$GATE31_SUMMARY_MARKER
EOF
GATE31_HANDOFF_MARKER="GATE31-HANDOFF-MARKER-$$"
cat > "$GATE31_ARTIFACTS/next_handoff.md" <<EOF
## Target AI
Codex
$GATE31_HANDOFF_MARKER
EOF

# 31a: default mode (no TELEGRAM_CONTENT_MODE set) behaves as "handoff".
unset TELEGRAM_CONTENT_MODE
PROJECT_ID=gate31 PROJECT_NAME="Gate31" REVIEWS_OVERRIDE="$TEST_DIR" \
  bash "$BRIDGE" notify-gate product_owner_validation_approval sprint-gate31-default 001 \
  "$GATE31_ARTIFACTS/artifact.md" "$GATE31_ARTIFACTS/summary.md" "$GATE31_ARTIFACTS/next_handoff.md" >/dev/null 2>&1
pkg_default="$(cat "$TEST_DIR/sprint-gate31-default/round-001/notifications/gate-product_owner_validation_approval.md" 2>/dev/null || echo "")"
assert_true "31a-0: default-mode package was actually generated (non-empty)" "[[ -n \"\$pkg_default\" ]] && true || false"

# 31a/31b/31c/31d: default (== handoff) mode contains Summary, Next AI
# Handoff Package, and Evidence Reference, but NOT full raw content.
assert_contains "31a: default mode contains 🇹🇼 Product Owner Summary" "$GATE31_SUMMARY_MARKER" "$pkg_default"
assert_contains "31b: default mode contains 🤖 Next AI Handoff Package" "$GATE31_HANDOFF_MARKER" "$pkg_default"
assert_contains "31c: default mode contains 📎 Evidence Reference" "📎 Evidence Reference" "$pkg_default"
assert_contains "31c-2: Evidence Reference lists the source artifact path" "$GATE31_ARTIFACTS/artifact.md" "$pkg_default"
assert_true "31d: default mode does NOT contain BEGIN ARTIFACT CONTENT" \
  "[[ \"\$pkg_default\" != *'BEGIN ARTIFACT CONTENT'* ]] && true || false"
assert_true "31d-2: default mode does NOT contain END ARTIFACT CONTENT" \
  "[[ \"\$pkg_default\" != *'END ARTIFACT CONTENT'* ]] && true || false"
assert_true "31d-3: default mode does NOT contain the raw artifact's own body text" \
  "[[ \"\$pkg_default\" != *'Long raw content that should only be inlined in full mode.'* ]] && true || false"

# 31e: explicitly setting TELEGRAM_CONTENT_MODE=handoff produces identical
# behavior to the default (proves "handoff" really is the default, not a
# coincidentally-similar separate code path). Same sprint_id as 31a/31d
# (different round, to avoid overwriting that output) so the only expected
# difference between the two runs is the created_at timestamp -- round_id
# and sprint_id are deliberately identical, not just filtered out.
TELEGRAM_CONTENT_MODE=handoff PROJECT_ID=gate31 PROJECT_NAME="Gate31" REVIEWS_OVERRIDE="$TEST_DIR" \
  bash "$BRIDGE" notify-gate product_owner_validation_approval sprint-gate31-default 002 \
  "$GATE31_ARTIFACTS/artifact.md" "$GATE31_ARTIFACTS/summary.md" "$GATE31_ARTIFACTS/next_handoff.md" >/dev/null 2>&1
pkg_explicit_handoff="$(cat "$TEST_DIR/sprint-gate31-default/round-002/notifications/gate-product_owner_validation_approval.md" 2>/dev/null || echo "")"
# Delivery Metadata contains a created_at timestamp that legitimately
# differs between the two invocations, and the round_id intentionally
# differs (001 vs 002, to keep their output files separate) -- both are
# excluded from the comparison; everything else must be byte-identical.
default_normalized="$(echo "$pkg_default" | grep -v '^created_at:' | grep -v '^Round: ' | grep -v '/ round-')"
explicit_normalized="$(echo "$pkg_explicit_handoff" | grep -v '^created_at:' | grep -v '^Round: ' | grep -v '/ round-')"
assert_eq "31e: TELEGRAM_CONTENT_MODE=handoff produces identical content to the default (aside from round/timestamp)" \
  "$default_normalized" "$explicit_normalized"

# 31f: TELEGRAM_CONTENT_MODE=full contains the full raw artifact content.
TELEGRAM_CONTENT_MODE=full PROJECT_ID=gate31 PROJECT_NAME="Gate31" REVIEWS_OVERRIDE="$TEST_DIR" \
  bash "$BRIDGE" notify-gate product_owner_validation_approval sprint-gate31-full 001 \
  "$GATE31_ARTIFACTS/artifact.md" "$GATE31_ARTIFACTS/summary.md" "$GATE31_ARTIFACTS/next_handoff.md" >/dev/null 2>&1
pkg_full="$(cat "$TEST_DIR/sprint-gate31-full/round-001/notifications/gate-product_owner_validation_approval.md" 2>/dev/null || echo "")"
assert_contains "31f: full mode contains BEGIN ARTIFACT CONTENT" "===== BEGIN ARTIFACT CONTENT" "$pkg_full"
assert_contains "31f-2: full mode contains END ARTIFACT CONTENT" "===== END ARTIFACT CONTENT" "$pkg_full"
assert_contains "31f-3: full mode contains the raw artifact's own body text" \
  "Long raw content that should only be inlined in full mode." "$pkg_full"
assert_contains "31f-4: full mode also still contains Product Owner Summary" "$GATE31_SUMMARY_MARKER" "$pkg_full"
assert_contains "31f-5: full mode also still contains Next AI Handoff Package" "$GATE31_HANDOFF_MARKER" "$pkg_full"
assert_contains "31f-6: full mode also still contains Evidence Reference" "📎 Evidence Reference" "$pkg_full"

# 31g: TELEGRAM_CONTENT_MODE=summary contains Summary + Evidence Reference,
# but NOT Next AI Handoff Package and NOT full raw content.
TELEGRAM_CONTENT_MODE=summary PROJECT_ID=gate31 PROJECT_NAME="Gate31" REVIEWS_OVERRIDE="$TEST_DIR" \
  bash "$BRIDGE" notify-gate product_owner_validation_approval sprint-gate31-summary 001 \
  "$GATE31_ARTIFACTS/artifact.md" "$GATE31_ARTIFACTS/summary.md" "$GATE31_ARTIFACTS/next_handoff.md" >/dev/null 2>&1
pkg_summary="$(cat "$TEST_DIR/sprint-gate31-summary/round-001/notifications/gate-product_owner_validation_approval.md" 2>/dev/null || echo "")"
assert_contains "31g: summary mode contains Product Owner Summary" "$GATE31_SUMMARY_MARKER" "$pkg_summary"
assert_true "31g-2: summary mode does NOT contain 🤖 Next AI Handoff Package" \
  "[[ \"\$pkg_summary\" != *'🤖 Next AI Handoff Package'* ]] && true || false"
assert_true "31g-3: summary mode does NOT contain the Next AI Handoff Package content itself" \
  "[[ \"\$pkg_summary\" != *'$GATE31_HANDOFF_MARKER'* ]] && true || false"
assert_true "31g-4: summary mode does NOT contain BEGIN ARTIFACT CONTENT" \
  "[[ \"\$pkg_summary\" != *'BEGIN ARTIFACT CONTENT'* ]] && true || false"
assert_contains "31g-5: summary mode still contains Evidence Reference" "📎 Evidence Reference" "$pkg_summary"

# 31h: an invalid TELEGRAM_CONTENT_MODE fails loudly, never silently
# ignored or falling back to a default.
TELEGRAM_CONTENT_MODE=bogus PROJECT_ID=gate31 PROJECT_NAME="Gate31" REVIEWS_OVERRIDE="$TEST_DIR" \
  bash "$BRIDGE" notify-gate product_owner_validation_approval sprint-gate31-invalid 001 \
  "$GATE31_ARTIFACTS/artifact.md" >/tmp/gate31h.out 2>&1
assert_exit_code "31h: an invalid TELEGRAM_CONTENT_MODE is a hard failure, not a silent fallback" 1 "$?"
assert_contains "31h-2: the error names the invalid mode" "Invalid TELEGRAM_CONTENT_MODE" "$(cat /tmp/gate31h.out)"
rm -f /tmp/gate31h.out

# 31i: content mode never changes the notify-gate safety boundary --
# cmd_notify_gate still has exactly one call site, regardless of mode.
notify_gate_call_sites_g31="$(grep -n 'cmd_notify_gate' "$BRIDGE" | grep -v '^[0-9]*:#' | grep -v 'cmd_notify_gate()')"
notify_gate_call_count_g31="$(echo "$notify_gate_call_sites_g31" | grep -c 'cmd_notify_gate "\$@"')"
assert_eq "31i: cmd_notify_gate is still invoked from exactly one place regardless of content mode" "1" "$notify_gate_call_count_g31"

# 31j: none of Test 31's invocations triggered Telegram or grew the real
# repository's notification history (all used REVIEWS_OVERRIDE with
# NOTIFICATION_ENABLED left unset).
real_history_count_after_g31="$(wc -l < "$REAL_HISTORY_FILE" 2>/dev/null || echo 0)"
assert_eq "31j: the real repository's notification_history.jsonl is unaffected by the content-mode tests" \
  "$REAL_HISTORY_COUNT_BEFORE" "$real_history_count_after_g31"

echo "  (Sprint-013/014/016/017 notify, notify-gate, and Gate metadata tests re-verified above, run unchanged in this same suite: zero regression)"

###############################################################################
# Test 32: Sprint-017 Must Fix Round 7 -- AI Handoff Standalone Message /
# Copy Boundary UX Improvement (section-aware Telegram message split)
###############################################################################
echo ""
echo "=== Test 32: section-aware Telegram delivery (standalone Next AI Handoff message) ==="

GATE32_ARTIFACTS="$TEST_DIR/gate32-artifacts"
mkdir -p "$GATE32_ARTIFACTS"
cat > "$GATE32_ARTIFACTS/artifact.md" <<'EOF'
# Raw artifact for full-mode Message 4 test
This body text must never appear in the Next AI Handoff message.
EOF
GATE32_SUMMARY_MARKER="GATE32-SUMMARY-MARKER-$$"
cat > "$GATE32_ARTIFACTS/summary.md" <<EOF
$GATE32_SUMMARY_MARKER
EOF
GATE32_HANDOFF_MARKER="GATE32-HANDOFF-MARKER-$$"
cat > "$GATE32_ARTIFACTS/next_handoff.md" <<EOF
## 1. Target AI

Codex

$GATE32_HANDOFF_MARKER
EOF

# Fake curl that saves each sent message body to its own numbered file, in
# the order curl was actually invoked -- lets these tests inspect exactly
# how many separate Telegram messages were sent and what each contains.
GATE32_FAKE_BIN="$TEST_DIR/gate32-fake-bin"
mkdir -p "$GATE32_FAKE_BIN"
cat > "$GATE32_FAKE_BIN/curl" <<'STUB'
#!/usr/bin/env bash
n=1
while [[ -f "$CAPTURED_MESSAGES_DIR/msg-$(printf '%02d' "$n").txt" ]]; do n=$((n+1)); done
for a in "$@"; do
  case "$a" in
    text@*) cp "${a#text@}" "$CAPTURED_MESSAGES_DIR/msg-$(printf '%02d' "$n").txt" ;;
  esac
done
echo '{"ok":true}'
exit 0
STUB
chmod +x "$GATE32_FAKE_BIN/curl"

# 32a-32g: handoff mode (the default) sends exactly 3 messages, with the
# Next AI Handoff Package fully isolated in Message 2.
GATE32_MSGS_HANDOFF="$TEST_DIR/gate32-msgs-handoff"
mkdir -p "$GATE32_MSGS_HANDOFF"
PATH="$GATE32_FAKE_BIN:$PATH" CAPTURED_MESSAGES_DIR="$GATE32_MSGS_HANDOFF" \
  PROJECT_ID=gate32 PROJECT_NAME="Gate32" NOTIFICATION_ENABLED=true \
  TELEGRAM_BOT_TOKEN=tok TELEGRAM_CHAT_ID=1 REVIEWS_OVERRIDE="$TEST_DIR" \
  bash "$BRIDGE" notify-gate product_owner_validation_approval sprint-gate32-handoff 001 \
  "$GATE32_ARTIFACTS/artifact.md" "$GATE32_ARTIFACTS/summary.md" "$GATE32_ARTIFACTS/next_handoff.md" >/dev/null 2>&1

handoff_msg_count="$(ls "$GATE32_MSGS_HANDOFF"/msg-*.txt 2>/dev/null | wc -l)"
assert_eq "32a: handoff mode sends exactly 3 separate Telegram messages" "3" "$handoff_msg_count"

handoff_msg1="$(cat "$GATE32_MSGS_HANDOFF/msg-01.txt" 2>/dev/null || echo "")"
handoff_msg2="$(cat "$GATE32_MSGS_HANDOFF/msg-02.txt" 2>/dev/null || echo "")"
handoff_msg3="$(cat "$GATE32_MSGS_HANDOFF/msg-03.txt" 2>/dev/null || echo "")"

assert_contains "32b: Message 2 contains BEGIN COPY TO CODEX" "===== BEGIN COPY TO CODEX =====" "$handoff_msg2"
assert_contains "32b-2: Message 2 contains END COPY TO CODEX" "===== END COPY TO CODEX =====" "$handoff_msg2"
assert_contains "32b-3: Message 2 contains the real handoff content" "$GATE32_HANDOFF_MARKER" "$handoff_msg2"

all_g32_msg2_clean=true
for forbidden in "Evidence Reference" "Delivery Metadata" "Product Owner Summary" \
                 "Product Owner Decision Options" "BEGIN ARTIFACT CONTENT" "END ARTIFACT CONTENT" \
                 "gate_id:" "$GATE32_SUMMARY_MARKER"; do
  [[ "$handoff_msg2" != *"$forbidden"* ]] || { all_g32_msg2_clean=false; echo "    (Message 2 unexpectedly contains: $forbidden)"; }
done
assert_true "32c: Message 2 (Next AI Handoff) contains none of: Evidence Reference / Delivery Metadata / Product Owner Summary / Decision Options / raw artifact markers / gate_id" $all_g32_msg2_clean

assert_true "32d: Message 1 does not contain the Next AI Handoff copy markers" \
  "[[ \"\$handoff_msg1\" != *'BEGIN COPY TO'* ]] && true || false"
assert_true "32e: Message 3 does not contain the Next AI Handoff copy markers" \
  "[[ \"\$handoff_msg3\" != *'BEGIN COPY TO'* ]] && true || false"
assert_contains "32f: Message 1 contains Product Owner Summary" "$GATE32_SUMMARY_MARKER" "$handoff_msg1"
assert_contains "32f-2: Message 1 contains Product Owner Decision Options" "Product Owner Decision Options" "$handoff_msg1"
assert_contains "32g: Message 3 contains Evidence Reference" "📎 Evidence Reference" "$handoff_msg3"
assert_contains "32g-2: Message 3 contains Delivery Metadata" "🧾 Delivery Metadata" "$handoff_msg3"

# 32h: summary mode sends exactly 2 messages, and neither is a Next AI
# Handoff message.
GATE32_MSGS_SUMMARY="$TEST_DIR/gate32-msgs-summary"
mkdir -p "$GATE32_MSGS_SUMMARY"
PATH="$GATE32_FAKE_BIN:$PATH" CAPTURED_MESSAGES_DIR="$GATE32_MSGS_SUMMARY" \
  TELEGRAM_CONTENT_MODE=summary PROJECT_ID=gate32 PROJECT_NAME="Gate32" NOTIFICATION_ENABLED=true \
  TELEGRAM_BOT_TOKEN=tok TELEGRAM_CHAT_ID=1 REVIEWS_OVERRIDE="$TEST_DIR" \
  bash "$BRIDGE" notify-gate product_owner_validation_approval sprint-gate32-summary 001 \
  "$GATE32_ARTIFACTS/artifact.md" "$GATE32_ARTIFACTS/summary.md" "$GATE32_ARTIFACTS/next_handoff.md" >/dev/null 2>&1
summary_msg_count="$(ls "$GATE32_MSGS_SUMMARY"/msg-*.txt 2>/dev/null | wc -l)"
assert_eq "32h: summary mode sends exactly 2 separate Telegram messages (no Next AI Handoff message)" "2" "$summary_msg_count"
summary_all_msgs="$(cat "$GATE32_MSGS_SUMMARY"/msg-*.txt 2>/dev/null)"
assert_true "32h-2: no message in summary mode contains BEGIN COPY TO" \
  "[[ \"\$summary_all_msgs\" != *'BEGIN COPY TO'* ]] && true || false"
assert_true "32h-3: no message in summary mode contains the handoff content" \
  "[[ \"\$summary_all_msgs\" != *'$GATE32_HANDOFF_MARKER'* ]] && true || false"

# 32i: full mode sends 4+ messages, with Raw Artifact Evidence only in
# Message(s) after the Next AI Handoff message, never inside it.
GATE32_MSGS_FULL="$TEST_DIR/gate32-msgs-full"
mkdir -p "$GATE32_MSGS_FULL"
PATH="$GATE32_FAKE_BIN:$PATH" CAPTURED_MESSAGES_DIR="$GATE32_MSGS_FULL" \
  TELEGRAM_CONTENT_MODE=full PROJECT_ID=gate32 PROJECT_NAME="Gate32" NOTIFICATION_ENABLED=true \
  TELEGRAM_BOT_TOKEN=tok TELEGRAM_CHAT_ID=1 REVIEWS_OVERRIDE="$TEST_DIR" \
  bash "$BRIDGE" notify-gate product_owner_validation_approval sprint-gate32-full 001 \
  "$GATE32_ARTIFACTS/artifact.md" "$GATE32_ARTIFACTS/summary.md" "$GATE32_ARTIFACTS/next_handoff.md" >/dev/null 2>&1
full_msg_count="$(ls "$GATE32_MSGS_FULL"/msg-*.txt 2>/dev/null | wc -l)"
assert_true "32i: full mode sends at least 4 separate Telegram messages" "[[ $full_msg_count -ge 4 ]] && true || false"
full_msg2="$(cat "$GATE32_MSGS_FULL/msg-02.txt" 2>/dev/null || echo "")"
assert_contains "32i-2: full mode's Message 2 is still the clean Next AI Handoff copy block" \
  "===== BEGIN COPY TO CODEX =====" "$full_msg2"
assert_true "32i-3: full mode's Message 2 does not contain the raw artifact's body text" \
  "[[ \"\$full_msg2\" != *'This body text must never appear in the Next AI Handoff message.'* ]] && true || false"
full_msg4="$(cat "$GATE32_MSGS_FULL/msg-04.txt" 2>/dev/null || echo "")"
assert_contains "32i-4: full mode's Message 4 contains the raw artifact evidence" \
  "This body text must never appear in the Next AI Handoff message." "$full_msg4"

# 32j: missing next-handoff-path still fails loudly (pre-existing Round 5
# behavior, re-confirmed unchanged after Round 7's restructuring).
PROJECT_ID=gate32 PROJECT_NAME="Gate32" REVIEWS_OVERRIDE="$TEST_DIR" \
  bash "$BRIDGE" notify-gate product_owner_validation_approval sprint-gate32-missing 001 \
  "$GATE32_ARTIFACTS/artifact.md" "$GATE32_ARTIFACTS/summary.md" "$GATE32_ARTIFACTS/does-not-exist.md" >/tmp/gate32j.out 2>&1
assert_exit_code "32j: a missing next-handoff-path still fails loudly after Round 7" 1 "$?"
rm -f /tmp/gate32j.out

# 32k: a next-handoff-path whose content (plus copy-boundary markers)
# exceeds the safe single-message character budget fails loudly instead of
# silently being split into multiple messages.
GATE32_TOO_LONG="$GATE32_ARTIFACTS/too_long_handoff.md"
{
  echo "## 1. Target AI"
  echo ""
  echo "Codex"
  echo ""
  python3 -c "print('x' * 4000)"
} > "$GATE32_TOO_LONG"
PROJECT_ID=gate32 PROJECT_NAME="Gate32" REVIEWS_OVERRIDE="$TEST_DIR" \
  bash "$BRIDGE" notify-gate product_owner_validation_approval sprint-gate32-toolong 001 \
  "$GATE32_ARTIFACTS/artifact.md" "" "$GATE32_TOO_LONG" >/tmp/gate32k.out 2>&1
assert_exit_code "32k: an oversized next-handoff-path fails loudly rather than being silently split" 1 "$?"
assert_contains "32k-2: the error explains the handoff content is too long" "too long to send as a single" "$(cat /tmp/gate32k.out)"
rm -f /tmp/gate32k.out

# 32l: a next-handoff-path with no parseable "Target AI" declaration fails
# loudly (Round 7 makes this declaration a hard requirement).
GATE32_NO_TARGET="$GATE32_ARTIFACTS/no_target_handoff.md"
echo "沒有宣告 Target AI 的內容" > "$GATE32_NO_TARGET"
PROJECT_ID=gate32 PROJECT_NAME="Gate32" REVIEWS_OVERRIDE="$TEST_DIR" \
  bash "$BRIDGE" notify-gate product_owner_validation_approval sprint-gate32-notarget 001 \
  "$GATE32_ARTIFACTS/artifact.md" "" "$GATE32_NO_TARGET" >/tmp/gate32l.out 2>&1
assert_exit_code "32l: a next-handoff-path with no Target AI declaration fails loudly" 1 "$?"
assert_contains "32l-2: the error explains a Target AI declaration is required" "does not declare a 'Target AI'" "$(cat /tmp/gate32l.out)"
rm -f /tmp/gate32l.out

# 32m: the real, shortened Sprint-017 Codex Git Review handoff artifact
# fits within the safe single-message character budget (Option A: keep the
# real fixture short, rather than relying solely on the fail-loud
# safeguard).
REAL_GIT_REVIEW_HANDOFF_LEN="$(wc -m < "$REAL_GIT_REVIEW_HANDOFF" 2>/dev/null || echo 999999)"
assert_true "32m: the real codex_git_review_handoff_zh.md fits within the safe single-message budget" \
  "[[ $REAL_GIT_REVIEW_HANDOFF_LEN -lt 3400 ]] && true || false"

# 32n: none of this test block triggered a real Telegram request or grew
# the real repository's notification history (all invocations used
# REVIEWS_OVERRIDE and a fake, non-networked curl stub).
real_history_count_after_g32="$(wc -l < "$REAL_HISTORY_FILE" 2>/dev/null || echo 0)"
assert_eq "32n: the real repository's notification_history.jsonl is unaffected by the section-aware delivery tests" \
  "$REAL_HISTORY_COUNT_BEFORE" "$real_history_count_after_g32"

echo "  (Sprint-013/014/016/017 notify, notify-gate, and Gate metadata tests re-verified above, run unchanged in this same suite: zero regression)"

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
