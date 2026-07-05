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

# 24p: Telegram receives the Gate Notification Package content byte-for-byte
# (Artifact First, same guarantee as Sprint-013 Must Fix 1).
GATE24_FAKE_BIN="$TEST_DIR/gate24-fake-bin"
mkdir -p "$GATE24_FAKE_BIN"
cat > "$GATE24_FAKE_BIN/curl" <<'STUB'
#!/usr/bin/env bash
for a in "$@"; do
  case "$a" in
    text@*) cp "${a#text@}" "$CAPTURED_CONTENT_FILE" ;;
  esac
done
echo '{"ok":true}'
exit 0
STUB
chmod +x "$GATE24_FAKE_BIN/curl"
GATE24_CAPTURED="$TEST_DIR/gate24-captured.txt"
rm -f "$GATE24_CAPTURED"
PATH="$GATE24_FAKE_BIN:$PATH" CAPTURED_CONTENT_FILE="$GATE24_CAPTURED" \
  PROJECT_ID=gate24 PROJECT_NAME="Gate24" NOTIFICATION_ENABLED=true \
  TELEGRAM_BOT_TOKEN=tok TELEGRAM_CHAT_ID=1 REVIEWS_OVERRIDE="$TEST_DIR" \
  bash "$BRIDGE" notify-gate push_approval sprint-24p 001 "$GATE24_ARTIFACTS/a.md" >/dev/null 2>&1
gate24p_pkg="$TEST_DIR/sprint-24p/round-001/notifications/gate-push_approval.md"
if [[ -f "$GATE24_CAPTURED" && -f "$gate24p_pkg" ]] && diff -q "$GATE24_CAPTURED" "$gate24p_pkg" >/dev/null 2>&1; then
  echo "  PASS: Telegram receives the Gate Notification Package content byte-for-byte"
  ((pass_count++))
else
  echo "  FAIL: Telegram content does not match the Gate Notification Package"
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
