#!/usr/bin/env bash
# review_bridge.sh — Review Bridge Automation MVP
#
# Responsibilities:
#   1. Initialize sprint directory and sprint_meta.env
#   2. Create input-artifact skeletons based on Sprint Type
#   3. Check required input artifacts exist
#   4. Validate final_consensus.md placement (post-finalize, pre-commit)
#   5. Produce consensus_report.md from input artifacts & deterministic markers
#   6. Produce final_consensus.md when consensus_report.md says Gate PASS
#
# Out of scope:
#   AI review, Claude/Codex calls, auto-loop, auto-commit, product code.

set -euo pipefail

###############################################################################
# Helpers
###############################################################################

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REVIEWS_DIR="${REVIEWS_OVERRIDE:-$REPO_ROOT/reviews}"

die() { echo "ERROR: $*" >&2; exit 1; }

die_usage() { echo "ERROR: $*" >&2; echo "Run 'review_bridge.sh' without arguments for usage." >&2; exit 1; }

usage() {
  cat <<'EOF'
Usage: review_bridge.sh <command> [arguments...] [--dry-run]

Review Bridge Automation MVP — manages sprint review artifacts and consensus gates.

Commands:
  init                        <sprint-id> [<round>]
                              Create sprint directory, sprint_meta.env, and optional round directory.
  skeleton                    <sprint-id> <round> --type <implementation|documentation>
                              Create input-artifact skeletons. Does NOT create gate artifacts.
  check                       <sprint-id> <round>
                              Check required input artifacts. Reports Missing / Placeholder / Ready.
  validate-final-consensus    <sprint-id>
                              Validate final_consensus.md placement (post-finalize, pre-commit).
  consensus                   <sprint-id> <round>
                              Parse deterministic markers and produce consensus_report.md.
  finalize                    <sprint-id> <round>
                              Produce final_consensus.md only when Gate Status is PASS.
  notify                      <sprint-id> <round> <event-type> <artifact-path>
                              Generate a Notification Package, deduplicate, and optionally deliver
                              to Telegram (see docs/development/notification-package-specification.md).
                              Requires PROJECT_ID and PROJECT_NAME env vars. Best-effort: delivery
                              failure never blocks or fails the underlying Sprint/Review Bridge flow.

Notes:
  - skeleton creates placeholder input artifacts only.
  - Before running consensus, replace placeholders with actual review content.
  - Placeholder files are detected by the marker "TEMPLATE ONLY" in the file body.
  - Placeholder files cannot pass consensus.
  - Implementation Sprint requires actual content in:
      architecture.md
      claude_report.md
      codex_review.md
      claude_reply.md
      codex_final_review.md
  - Documentation Sprint requires actual content in:
      reviewed_document.md
      claude_report.md
      codex_review.md
      claude_reply.md
      codex_final_review.md
  - codex_prompt.md is a review prompt artifact and does not require deterministic markers.
EOF
  exit 1
}

# Parse --dry-run from args; return remaining args.
DRY_RUN=false
parse_dry_run() {
  local args=("$@")
  for a in "${args[@]}"; do
    if [[ "$a" == "--dry-run" ]]; then
      DRY_RUN=true
    fi
  done
}

run_or_echo() {
  if $DRY_RUN; then
    echo "[dry-run] $*"
  else
    "$@"
  fi
}

meta_path() {
  local sprint_id="$1"
  echo "$REVIEWS_DIR/$sprint_id/sprint_meta.env"
}

# Validate sprint_id and round against path traversal.
# sprint_id: only lowercase alphanumeric, digits, hyphens.
# round: exactly 3 digits.
validate_id() {
  local id="$1" label="$2"
  if [[ ! "$id" =~ ^[a-z0-9][a-z0-9-]*[a-z0-9]$ ]] && [[ ! "$id" =~ ^[a-z0-9]$ ]]; then
    die "Invalid $label: '$id' (only lowercase alphanumeric and hyphens allowed)"
  fi
  # Reject path traversal patterns
  if [[ "$id" == *".."* ]] || [[ "$id" == *"/"* ]] || [[ "$id" == *" "* ]]; then
    die "Invalid $label: '$id' (contains forbidden characters)"
  fi
}

validate_round() {
  local round="$1"
  if [[ ! "$round" =~ ^[0-9]+$ ]]; then
    die "Invalid round: '$round' (must be a positive integer)"
  fi
  # Safe normalization: strip leading zeros via arithmetic, then pad
  local num=$((10#$round))
  if (( num < 1 )); then
    die "Invalid round: must be >= 1"
  fi
  printf '%03d' "$num"
}

load_meta() {
  local sprint_id="$1"
  local meta
  meta="$(meta_path "$sprint_id")"
  [[ -f "$meta" ]] || die "sprint_meta.env not found: $meta"

  SPRINT_ID=""
  SPRINT_TYPE=""
  CURRENT_ROUND=""

  while IFS= read -r line || [[ -n "$line" ]]; do
    case "$line" in
      SPRINT_ID=*)
        SPRINT_ID="${line#SPRINT_ID=}"
        ;;
      SPRINT_TYPE=*)
        SPRINT_TYPE="${line#SPRINT_TYPE=}"
        ;;
      CURRENT_ROUND=*)
        CURRENT_ROUND="${line#CURRENT_ROUND=}"
        ;;
    esac
  done < "$meta"
}

###############################################################################
# Command: init
###############################################################################

cmd_init() {
  local sprint_id="${1:?Usage: review_bridge.sh init <sprint-id>}"
  shift

  parse_dry_run "$@"

  # Optional round number argument
  local round=""
  for arg in "$@"; do
    if [[ "$arg" != --* ]]; then
      round="$arg"
    fi
  done

  validate_id "$sprint_id" "sprint-id"

  local sprint_dir="$REVIEWS_DIR/$sprint_id"
  local meta_file="$sprint_dir/sprint_meta.env"

  if $DRY_RUN; then
    echo "[dry-run] Would create directory: $sprint_dir"
    echo "[dry-run] Would write $meta_file"
    if [[ -n "$round" ]]; then
      local normalized
      normalized="$(validate_round "$round")"
      echo "[dry-run] Would create round directory: $sprint_dir/round-$normalized"
    fi
    return
  fi

  # Create sprint directory and metadata
  mkdir -p "$sprint_dir"

  if [[ -f "$meta_file" ]]; then
    # Update existing metadata
    sed -i "s/^SPRINT_ID=.*/SPRINT_ID=$sprint_id/" "$meta_file"
  else
    cat > "$meta_file" <<EOF
SPRINT_ID=$sprint_id
SPRINT_TYPE=
CURRENT_ROUND=
EOF
  fi

  echo "Created: $sprint_dir"
  echo "Written: $meta_file"

  # Create round directory if round number provided
  if [[ -n "$round" ]]; then
    local normalized
    normalized="$(validate_round "$round")"
    local round_dir="$sprint_dir/round-$normalized"
    if [[ -d "$round_dir" ]]; then
      die "Round directory already exists: $round_dir"
    fi
    mkdir -p "$round_dir"
    echo "Created: $round_dir"
  fi
}

###############################################################################
# Command: skeleton
###############################################################################

cmd_skeleton() {
  local sprint_id="${1:?Usage: review_bridge.sh skeleton <sprint-id> <round> --type <type>}"
  shift

  parse_dry_run "$@"

  validate_id "$sprint_id" "sprint-id"

  local round=""
  local sprint_type=""

  # Parse positional and --type flag
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --type)
        sprint_type="${2:?--type requires a value (implementation|documentation)}"
        shift 2
        ;;
      --*)
        # Skip unknown flags like --dry-run (already parsed)
        shift
        ;;
      *)
        if [[ -z "$round" ]]; then
          round="$1"
        fi
        shift
        ;;
    esac
  done

  [[ -z "$round" ]] && die "round is required"

  round="$(validate_round "$round")"

  [[ -z "$sprint_type" ]] && die "--type is required (implementation|documentation)"
  [[ "$sprint_type" != "implementation" && "$sprint_type" != "documentation" ]] \
    && die "--type must be 'implementation' or 'documentation'"

  local round_dir="$REVIEWS_DIR/$sprint_id/round-$round"

  # Validate sprint_meta.env exists
  local meta_file
  meta_file="$(meta_path "$sprint_id")"
  [[ -f "$meta_file" ]] || die "sprint_meta.env not found. Run 'init' first."

  # Determine input artifacts based on sprint type
  local -a input_artifacts=()
  case "$sprint_type" in
    implementation)
      input_artifacts=(
        "architecture.md"
        "claude_report.md"
        "codex_prompt.md"
        "codex_review.md"
        "claude_reply.md"
        "codex_final_review.md"
      )
      ;;
    documentation)
      input_artifacts=(
        "reviewed_document.md"
        "claude_report.md"
        "codex_prompt.md"
        "codex_review.md"
        "claude_reply.md"
        "codex_final_review.md"
      )
      ;;
  esac

  if $DRY_RUN; then
    echo "[dry-run] Would create directory: $round_dir"
    for f in "${input_artifacts[@]}"; do
      echo "[dry-run] Would create skeleton: $round_dir/$f"
    done
    echo "[dry-run] Would update sprint_meta.env: SPRINT_TYPE=$sprint_type, CURRENT_ROUND=$round"
    return
  fi

  mkdir -p "$round_dir"

  for f in "${input_artifacts[@]}"; do
    local fp="$round_dir/$f"
    if [[ ! -f "$fp" ]]; then
      cat > "$fp" <<EOF
# $f

TEMPLATE ONLY

NOT READY FOR CONSENSUS

Replace with actual review content before running consensus.
EOF
    fi
  done

  # Update sprint_meta.env
  sed -i "s/^SPRINT_TYPE=.*/SPRINT_TYPE=$sprint_type/" "$meta_file"
  sed -i "s/^CURRENT_ROUND=.*/CURRENT_ROUND=$round/" "$meta_file"
}

###############################################################################
# Placeholder detection
###############################################################################

# Check if a file contains placeholder content.
# Returns 0 (true) if file is a placeholder, 1 (false) if it has real content.
is_placeholder() {
  local file="$1"
  # Skeleton-generated files contain this exact marker
  if grep -q "^TEMPLATE ONLY$" "$file" 2>/dev/null; then
    return 0
  fi
  return 1
}

# Per docs/development/consensus-workflow.md Fill Artifacts Step, codex_prompt.md
# is a review prompt artifact, not a review result, and is not in the list of
# files that must contain actual content before consensus runs. A placeholder
# codex_prompt.md must not block consensus.
CONSENSUS_BLOCKING_EXEMPT=("codex_prompt.md")

# Filter a required-artifacts array down to the ones whose placeholder status
# blocks consensus (i.e. excludes CONSENSUS_BLOCKING_EXEMPT).
# Usage: fill_artifacts=($(blocking_artifacts "${required[@]}"))
blocking_artifacts() {
  local f
  for f in "$@"; do
    local exempt=false
    local ex
    for ex in "${CONSENSUS_BLOCKING_EXEMPT[@]}"; do
      [[ "$f" == "$ex" ]] && exempt=true && break
    done
    $exempt || echo "$f"
  done
}

###############################################################################
# n8n Webhook Notification (optional, best-effort, non-blocking)
###############################################################################

# Shared best-effort POST used by every n8n notification hook below. Given an
# already-resolved webhook URL and JSON payload, sends one POST with a 5s
# timeout. Never affects the caller's exit code: dry-run prints what would be
# sent instead of sending; a missing curl binary or a failed request only
# produce a WARNING on stderr (never the URL itself, to avoid leaking it into
# logs). `label` identifies the notification in log messages (e.g.
# "claude_report.md", "codex_review"). `env_var_name` is only used in the
# dry-run / missing-curl messages (the variable name, not its value).
_post_n8n_notification() {
  local webhook_url="$1"
  local payload="$2"
  local label="$3"
  local env_var_name="$4"

  if $DRY_RUN; then
    echo "[dry-run] Would POST $label notification to $env_var_name"
    return 0
  fi

  if ! command -v curl >/dev/null 2>&1; then
    echo "WARNING: $env_var_name is set but 'curl' is not installed; skipping notification." >&2
    return 0
  fi

  if ! curl -fsS --max-time 5 -X POST "$webhook_url" \
        -H "Content-Type: application/json" \
        -d "$payload" >/dev/null 2>&1; then
    echo "WARNING: Failed to POST $label notification to N8N webhook. Continuing without notification." >&2
  fi

  return 0
}

# Escape a string for embedding as one JSON string value: backslash and
# double-quote first, then convert literal newline/CR/tab characters to their
# JSON escape sequences. Used for multi-line file content (handoff_package.md)
# where the lighter path-only escaping below is not sufficient.
_json_escape_multiline() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\r'/}"
  s="${s//$'\t'/\\t}"
  s="${s//$'\n'/\\n}"
  echo "$s"
}

# POST a JSON notification to N8N_CLAUDE_DONE_WEBHOOK_URL when claude_report.md
# is confirmed READY by `check`. Purely a notification: it never calls Claude
# or Codex, never modifies any file, and never affects the exit code of the
# calling command. If the variable is unset, this is a no-op — existing
# behavior is unchanged.
#
# `handoff_file` (optional, Sprint-010) is the path to the handoff_package.md
# written for this same gate, if any. When present, its full content is
# embedded as `handoff_package_content` so a remote n8n instance — which has
# no filesystem access to this repo — can push the Copyable Prompt straight
# into the Telegram message instead of only a path it cannot read.
# See docs/development/n8n-claude-done-notification.md.
notify_claude_report_done() {
  local sprint_id="$1"
  local round="$2"
  local file_path="$3"
  local handoff_file="${4:-}"

  local webhook_url="${N8N_CLAUDE_DONE_WEBHOOK_URL:-}"
  [[ -z "$webhook_url" ]] && return 0

  # sprint_id and round-<round> are already validated as safe kebab-case /
  # numeric by validate_id / validate_round, so only file_path needs light
  # JSON-string escaping.
  local escaped_path="${file_path//\\/\\\\}"
  escaped_path="${escaped_path//\"/\\\"}"

  local payload
  if [[ -n "$handoff_file" && -f "$handoff_file" ]]; then
    local escaped_handoff
    escaped_handoff="$(_json_escape_multiline "$(cat "$handoff_file")")"
    payload="$(printf '{"sprint_id":"%s","round_id":"round-%s","file_path":"%s","handoff_package_content":"%s"}' \
      "$sprint_id" "$round" "$escaped_path" "$escaped_handoff")"
  else
    payload="$(printf '{"sprint_id":"%s","round_id":"round-%s","file_path":"%s"}' \
      "$sprint_id" "$round" "$escaped_path")"
  fi

  _post_n8n_notification "$webhook_url" "$payload" "claude_report.md" "N8N_CLAUDE_DONE_WEBHOOK_URL"
}

# POST a JSON notification to N8N_CODEX_REVIEW_DONE_WEBHOOK_URL when
# codex_review.md or codex_final_review.md is confirmed READY by `check`.
# Same opt-in / best-effort / non-blocking guarantees as
# notify_claude_report_done above — it never calls Claude or Codex, never
# modifies any file, and never affects the exit code of the calling command.
# `review_type` must be "codex_review" or "codex_final_review".
#
# `handoff_file` (optional, Sprint-010) works exactly as in
# notify_claude_report_done above: when the caller passes the
# handoff_package.md written for this gate, its content is embedded as
# `handoff_package_content`. codex_final_review.md has no Handoff Package
# scenario defined in the Architecture, so its caller passes no handoff_file
# and the field is simply omitted — no fabricated or stale content is sent.
# See docs/development/n8n-codex-review-done-notification.md.
notify_codex_review_done() {
  local sprint_id="$1"
  local round="$2"
  local review_type="$3"
  local file_path="$4"
  local handoff_file="${5:-}"

  local webhook_url="${N8N_CODEX_REVIEW_DONE_WEBHOOK_URL:-}"
  [[ -z "$webhook_url" ]] && return 0

  local escaped_path="${file_path//\\/\\\\}"
  escaped_path="${escaped_path//\"/\\\"}"

  local payload
  if [[ -n "$handoff_file" && -f "$handoff_file" ]]; then
    local escaped_handoff
    escaped_handoff="$(_json_escape_multiline "$(cat "$handoff_file")")"
    payload="$(printf '{"sprint_id":"%s","round_id":"round-%s","review_type":"%s","file_path":"%s","handoff_package_content":"%s"}' \
      "$sprint_id" "$round" "$review_type" "$escaped_path" "$escaped_handoff")"
  else
    payload="$(printf '{"sprint_id":"%s","round_id":"round-%s","review_type":"%s","file_path":"%s"}' \
      "$sprint_id" "$round" "$review_type" "$escaped_path")"
  fi

  _post_n8n_notification "$webhook_url" "$payload" "$review_type" "N8N_CODEX_REVIEW_DONE_WEBHOOK_URL"
}

###############################################################################
# Handoff Package (Sprint-010, Architecture Baseline v1.0)
###############################################################################
#
# Review Bridge is the sole producer of handoff_package.md. Content is
# assembled purely from fixed templates and file path references already
# known to `check` — no LLM call, no new READY detection, no extra file scan
# or markdown parsing beyond what `check` already computed. Missing or
# placeholder source files are rendered as an explicit PLACEHOLDER reference
# rather than silently omitted or guessed at (Architecture section 8).

# Membership test against an already-computed classification array (e.g.
# ready[]). Reuses the classification `check` already computed for this
# invocation; does not re-scan the filesystem.
_array_contains() {
  local needle="$1"
  shift
  local x
  for x in "$@"; do
    [[ "$x" == "$needle" ]] && return 0
  done
  return 1
}

# Render the reference line for one artifact: the real relative path if it is
# in ready[], otherwise an explicit PLACEHOLDER line (never a silently wrong
# or fabricated reference).
# Usage: _handoff_ref <sprint_id> <round> <name> <ready...>
_handoff_ref() {
  local sprint_id="$1" round="$2" name="$3"
  shift 3
  local rel="reviews/$sprint_id/round-$round/$name"
  if _array_contains "$name" "$@"; then
    echo "$rel"
  else
    echo "PLACEHOLDER: $rel is not available (missing or placeholder)"
  fi
}

# Write handoff_package.md for the "Claude Implementation Completed ->
# Codex Review" gate (Architecture section 10.1). `arch_file` is
# "architecture.md" for implementation Sprints or "reviewed_document.md" for
# documentation Sprints, matching the Sprint Type already resolved by `check`.
write_handoff_package_claude_to_codex() {
  local sprint_id="$1" round="$2" round_dir="$3" arch_file="$4"
  shift 4
  local -a ready_arr=("$@")

  if $DRY_RUN; then
    echo "[dry-run] Would write $round_dir/handoff_package.md (Target AI: Codex)"
    return 0
  fi

  local arch_ref claude_ref
  arch_ref="$(_handoff_ref "$sprint_id" "$round" "$arch_file" "${ready_arr[@]}")"
  claude_ref="$(_handoff_ref "$sprint_id" "$round" "claude_report.md" "${ready_arr[@]}")"

  cat > "$round_dir/handoff_package.md" <<EOF
# Handoff Package

## 1. Target AI

Codex

## 2. Current Stage

Claude Implementation Completed

## 3. Objective

依已核准的 Architecture，Review $sprint_id round-$round 的 Claude Code Implementation，並產出 codex_review.md。

## 4. Required Reading

- PROJECT_BOOTSTRAP.md
- docs/development/consensus-workflow.md
- scripts/review_bridge.sh
- $arch_ref
- $claude_ref

## 5. Scope

- 檢查實作是否符合已核准的 Architecture。
- 檢查是否有 scope creep（範圍是否被自行擴大）。
- 檢查測試是否足夠、是否通過。
- 判斷是否有 Must Fix 或 Architecture Conflict。

## 6. Out of Scope

- 不新增 AI 自動互叫
- 不新增 Workflow Engine
- 不新增 Prompt Generator
- 不新增 Queue / Database
- 不改變 Manual Gate
- 不改變既有角色分工
- 不得修改程式碼（Codex 僅負責 Review）
- 不得 commit

## 7. Acceptance Criteria

- 產出 reviews/$sprint_id/round-$round/codex_review.md
- 明確標示 Gate Status、Must Fix、Architecture Conflict、Final Recommendation
- 未修改任何程式碼、未 commit

## 8. Copyable Prompt

請閱讀：

- PROJECT_BOOTSTRAP.md
- docs/development/consensus-workflow.md
- scripts/review_bridge.sh
- $arch_ref
- $claude_ref

工作：

為 $sprint_id round-$round 產生正式 Codex Review。

請完成以下工作：

1. 判斷是否符合 Architecture / Implementation Spec。
2. 判斷是否有 scope creep。
3. 判斷是否有 Architecture Conflict。
4. 判斷是否有 Must Fix。
5. 依 claude_report.md 描述的測試方式重新驗證測試。
6. 輸出：
   - Gate Status
   - Must Fix
   - Architecture Conflict
   - Final Recommendation

請覆寫：

reviews/$sprint_id/round-$round/codex_review.md

限制：

- 不修改 source code。
- 不 stage。
- 不 commit。
- 不 push。
- 只允許更新 reviews/$sprint_id/round-$round/codex_review.md。
EOF
}

# Write handoff_package.md for the "Codex Review Completed -> Claude fixes"
# gate (Architecture section 10.2).
write_handoff_package_codex_to_claude() {
  local sprint_id="$1" round="$2" round_dir="$3" arch_file="$4"
  shift 4
  local -a ready_arr=("$@")

  if $DRY_RUN; then
    echo "[dry-run] Would write $round_dir/handoff_package.md (Target AI: Claude Code)"
    return 0
  fi

  local arch_ref claude_ref codex_ref
  arch_ref="$(_handoff_ref "$sprint_id" "$round" "$arch_file" "${ready_arr[@]}")"
  claude_ref="$(_handoff_ref "$sprint_id" "$round" "claude_report.md" "${ready_arr[@]}")"
  codex_ref="$(_handoff_ref "$sprint_id" "$round" "codex_review.md" "${ready_arr[@]}")"

  cat > "$round_dir/handoff_package.md" <<EOF
# Handoff Package

## 1. Target AI

Claude Code

## 2. Current Stage

Codex Review Completed

## 3. Objective

只修正 $sprint_id round-$round 的 codex_review.md 所指出的問題，不擴大 Scope。

## 4. Required Reading

- PROJECT_BOOTSTRAP.md
- docs/development/consensus-workflow.md
- scripts/review_bridge.sh
- $arch_ref
- $claude_ref
- $codex_ref

## 5. Scope

- 依 codex_review.md 指出的 Must Fix / Architecture Conflict 項目進行修正。
- 更新 claude_reply.md，逐項回應 codex_review.md 的意見。

## 6. Out of Scope

- 不新增 AI 自動互叫
- 不新增 Workflow Engine
- 不新增 Prompt Generator
- 不新增 Queue / Database
- 不改變 Manual Gate
- 不改變既有角色分工
- 不得修正 codex_review.md 未提及的項目
- 不得擴大 Scope
- 不得 commit

## 7. Acceptance Criteria

- 產出 reviews/$sprint_id/round-$round/claude_reply.md，逐項回應 codex_review.md 的 Must Fix / Architecture Conflict
- 未擴大 Scope
- 未 commit

## 8. Copyable Prompt

請閱讀：

- PROJECT_BOOTSTRAP.md
- docs/development/consensus-workflow.md
- scripts/review_bridge.sh
- $arch_ref
- $claude_ref
- $codex_ref

工作：

只修正 codex_review.md 指出的問題，不擴大範圍。

請完成以下工作：

1. 閱讀 codex_review.md 的 Must Fix 與 Architecture Conflict。
2. 只針對這些項目進行修正或回應。
3. 完成後更新 claude_reply.md，逐項回應。
4. 回報測試方式與測試結果。

限制：

- 不擴大 Scope。
- 不修改 codex_review.md 未提及的項目。
- 不 commit。
EOF
}

###############################################################################
# Command: check
###############################################################################

cmd_check() {
  local sprint_id="${1:?Usage: review_bridge.sh check <sprint-id> <round>}"
  shift

  local round="${1:?Usage: review_bridge.sh check <sprint-id> <round>}"
  shift

  parse_dry_run "$@"

  validate_id "$sprint_id" "sprint-id"
  round="$(validate_round "$round")"

  # Load Sprint Type from metadata
  load_meta "$sprint_id"
  local stype="${SPRINT_TYPE:-}"
  [[ -z "$stype" ]] && die "SPRINT_TYPE not set in sprint_meta.env"
  [[ "$stype" == "implementation" || "$stype" == "documentation" ]] \
    || die "SPRINT_TYPE must be 'implementation' or 'documentation', got: '$stype'"

  local round_dir="$REVIEWS_DIR/$sprint_id/round-$round"
  [[ -d "$round_dir" ]] || die "Round directory not found: $round_dir"

  # Determine required input artifacts
  local -a required=()
  case "$stype" in
    implementation)
      required=(
        "architecture.md"
        "claude_report.md"
        "codex_prompt.md"
        "codex_review.md"
        "claude_reply.md"
        "codex_final_review.md"
      )
      ;;
    documentation)
      required=(
        "reviewed_document.md"
        "claude_report.md"
        "codex_prompt.md"
        "codex_review.md"
        "claude_reply.md"
        "codex_final_review.md"
      )
      ;;
  esac

  # Artifacts whose placeholder status actually blocks consensus (excludes
  # codex_prompt.md per consensus-workflow.md Fill Artifacts Step).
  local -a fill_artifacts=()
  while IFS= read -r f; do
    fill_artifacts+=("$f")
  done < <(blocking_artifacts "${required[@]}")

  local missing=()
  local placeholder=()
  local ready=()
  local blocking_placeholder=()

  for f in "${required[@]}"; do
    local fp="$round_dir/$f"
    if [[ ! -f "$fp" ]]; then
      missing+=("$f")
    elif is_placeholder "$fp"; then
      placeholder+=("$f")
    else
      ready+=("$f")
    fi
  done

  for f in "${fill_artifacts[@]}"; do
    local fp="$round_dir/$f"
    if [[ -f "$fp" ]] && is_placeholder "$fp"; then
      blocking_placeholder+=("$f")
    fi
  done

  # Architecture-defined Handoff Package source filename for this Sprint Type
  # (Sprint-010 section 10.1/10.2): "architecture.md" for implementation,
  # "reviewed_document.md" for documentation.
  local arch_file="architecture.md"
  [[ "$stype" == "documentation" ]] && arch_file="reviewed_document.md"

  # Optional, best-effort n8n notifications + Handoff Package generation:
  # reuse the ready[] classification already computed above — no new READY
  # detection, no extra file scan, no extra markdown parsing is introduced
  # here. Each case fires independently of the overall gate status of the
  # other artifacts. Notifications are a no-op unless the corresponding
  # N8N_*_WEBHOOK_URL is set; Handoff Package generation always runs when its
  # gate condition is met (Review Bridge is the sole Handoff Package
  # producer, per Sprint-010 Architecture section 5.1).
  #
  # Handoff Package generation runs BEFORE its gate's notification so the
  # freshly written handoff_package.md can be attached to that same
  # notification's payload (see notify_claude_report_done /
  # notify_codex_review_done "handoff_file" parameter above). codex_final_review.md
  # has no Handoff Package scenario in the Architecture, so its notification
  # is sent with no handoff_file — no stale or fabricated content attached.
  local handoff_file="$round_dir/handoff_package.md"
  for f in "${ready[@]}"; do
    case "$f" in
      claude_report.md)
        write_handoff_package_claude_to_codex "$sprint_id" "$round" "$round_dir" "$arch_file" "${ready[@]}"
        notify_claude_report_done "$sprint_id" "$round" "$round_dir/claude_report.md" "$handoff_file"
        ;;
      codex_review.md)
        write_handoff_package_codex_to_claude "$sprint_id" "$round" "$round_dir" "$arch_file" "${ready[@]}"
        notify_codex_review_done "$sprint_id" "$round" "codex_review" "$round_dir/codex_review.md" "$handoff_file"
        ;;
      codex_final_review.md)
        notify_codex_review_done "$sprint_id" "$round" "codex_final_review" "$round_dir/codex_final_review.md"
        ;;
    esac
  done

  # Print per-file status
  if [[ ${#missing[@]} -gt 0 ]]; then
    echo "Missing:"
    for m in "${missing[@]}"; do
      echo "  - $m: MISSING"
    done
  fi

  if [[ ${#placeholder[@]} -gt 0 ]]; then
    echo "Placeholder:"
    for p in "${placeholder[@]}"; do
      echo "  - $p: PLACEHOLDER"
    done
  fi

  if [[ ${#ready[@]} -gt 0 ]]; then
    echo "Ready:"
    for r in "${ready[@]}"; do
      echo "  - $r: READY"
    done
  fi

  # Overall status
  if [[ ${#missing[@]} -gt 0 ]]; then
    echo ""
    echo "FAIL: ${#missing[@]} missing, ${#placeholder[@]} placeholder(s)."
    exit 1
  elif [[ ${#blocking_placeholder[@]} -gt 0 ]]; then
    echo ""
    echo "WARNING: ${#blocking_placeholder[@]} placeholder(s) blocking consensus. Replace before running consensus."
    echo "PLACEHOLDER"
  elif [[ ${#placeholder[@]} -gt 0 ]]; then
    echo ""
    echo "PASS: All artifacts required for consensus are ready. ${#placeholder[@]} non-blocking placeholder(s) (codex_prompt.md is not required for consensus)."
  else
    echo ""
    echo "PASS: All ${#ready[@]} input artifacts ready."
  fi
}

###############################################################################
# Command: validate-final-consensus
###############################################################################

cmd_validate_final_consensus() {
  local sprint_id="${1:?Usage: review_bridge.sh validate-final-consensus <sprint-id>}"
  shift

  parse_dry_run "$@"

  validate_id "$sprint_id" "sprint-id"

  local sprint_dir="$REVIEWS_DIR/$sprint_id"
  [[ -d "$sprint_dir" ]] || die "Sprint directory not found: $sprint_dir"

  # Find all round directories, sorted by round number
  local -a round_dirs=()
  while IFS= read -r d; do
    round_dirs+=("$d")
  done < <(find "$sprint_dir" -maxdepth 1 -type d -name 'round-*' | sort)

  if [[ ${#round_dirs[@]} -eq 0 ]]; then
    die "No round directories found under $sprint_dir"
  fi

  # Last round = highest numbered
  local last_round="${round_dirs[-1]}"
  local last_round_name
  last_round_name="$(basename "$last_round")"

  local found_any_final=false
  local errors=()

  for rd in "${round_dirs[@]}"; do
    local fc="$rd/final_consensus.md"
    if [[ -f "$fc" ]]; then
      local bn
      bn="$(basename "$rd")"
      if [[ "$bn" != "$last_round_name" ]]; then
        errors+=("final_consensus.md exists in non-final round: $bn")
      else
        found_any_final=true
      fi
    fi
  done

  if ! $found_any_final; then
    errors+=("final_consensus.md not found in last round ($last_round_name)")
  fi

  if [[ ${#errors[@]} -gt 0 ]]; then
    echo "FAIL:"
    for e in "${errors[@]}"; do
      echo "  - $e"
    done
    exit 1
  fi

  echo "PASS: final_consensus.md is correctly placed in $last_round_name."
}

###############################################################################
# Marker parsing helpers
###############################################################################

# Extract marker value from a file.
# Usage: parse_marker <file> <marker-key>
# Returns the value after the colon, trimmed.
parse_marker() {
  local file="$1"
  local key="$2"
  local line

  line="$(grep -m1 "^${key}:" "$file" 2>/dev/null || true)"
  if [[ -z "$line" ]]; then
    echo ""
    return
  fi

  # Extract value after first colon, trim whitespace
  local val="${line#*:}"
  val="$(echo "$val" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  echo "$val"
}

###############################################################################
# Command: consensus
###############################################################################

cmd_consensus() {
  local sprint_id="${1:?Usage: review_bridge.sh consensus <sprint-id> <round>}"
  shift

  local round="${1:?Usage: review_bridge.sh consensus <sprint-id> <round>}"
  shift

  parse_dry_run "$@"

  validate_id "$sprint_id" "sprint-id"
  round="$(validate_round "$round")"

  # Load Sprint Type from metadata
  load_meta "$sprint_id"
  local stype="${SPRINT_TYPE:-}"
  [[ -z "$stype" ]] && die "SPRINT_TYPE not set in sprint_meta.env"
  [[ "$stype" == "implementation" || "$stype" == "documentation" ]] \
    || die "SPRINT_TYPE must be 'implementation' or 'documentation', got: '$stype'"

  local round_dir="$REVIEWS_DIR/$sprint_id/round-$round"
  [[ -d "$round_dir" ]] || die "Round directory not found: $round_dir"

  # Determine required input artifacts
  local -a required=()
  case "$stype" in
    implementation)
      required=("architecture.md" "claude_report.md" "codex_prompt.md" \
                "codex_review.md" "claude_reply.md" "codex_final_review.md")
      ;;
    documentation)
      required=("reviewed_document.md" "claude_report.md" "codex_prompt.md" \
                "codex_review.md" "claude_reply.md" "codex_final_review.md")
      ;;
  esac

  # Check existence of required input artifacts
  local missing=()
  for f in "${required[@]}"; do
    if [[ ! -f "$round_dir/$f" ]]; then
      missing+=("$f")
    fi
  done

  # Parse deterministic markers from each input artifact
  local codex_review="$round_dir/codex_review.md"
  local claude_reply="$round_dir/claude_reply.md"
  local codex_final="$round_dir/codex_final_review.md"
  local claude_report="$round_dir/claude_report.md"

  local must_fix="" arch_conflict="" codex_rec=""
  local reply_must_fix="" reply_arch_conflict="" reply_rec=""
  local final_rec="" scope_expansion=""

  if [[ -f "$codex_review" ]]; then
    must_fix="$(parse_marker "$codex_review" "Must Fix")"
    arch_conflict="$(parse_marker "$codex_review" "Architecture Conflict")"
    codex_rec="$(parse_marker "$codex_review" "Final Recommendation")"
  fi

  if [[ -f "$claude_reply" ]]; then
    reply_must_fix="$(parse_marker "$claude_reply" "Must Fix Addressed")"
    reply_arch_conflict="$(parse_marker "$claude_reply" "Architecture Conflict Addressed")"
    reply_rec="$(parse_marker "$claude_reply" "Final Recommendation")"
  fi

  if [[ -f "$codex_final" ]]; then
    final_rec="$(parse_marker "$codex_final" "Final Recommendation")"
  fi

  if [[ -f "$claude_report" ]]; then
    scope_expansion="$(parse_marker "$claude_report" "Scope Expansion")"
  fi

  # Evaluate Gate Status — deterministic marker checks only
  local fail_reasons=()

  if [[ ${#missing[@]} -gt 0 ]]; then
    fail_reasons+=("Missing input artifacts: ${missing[*]}")
  fi

  # 1. codex_review Must Fix — missing or non-None → FAIL
  if [[ "$must_fix" != "None" ]]; then
    fail_reasons+=("codex_review Must Fix is not None: ${must_fix:-<not found>}")
  fi

  # 2. codex_review Architecture Conflict — missing or non-None → FAIL
  if [[ "$arch_conflict" != "None" ]]; then
    fail_reasons+=("codex_review Architecture Conflict is not None: ${arch_conflict:-<not found>}")
  fi

  # 3. codex_review Final Recommendation
  if [[ "$codex_rec" != "PASS" ]]; then
    fail_reasons+=("codex_review Final Recommendation is not PASS: ${codex_rec:-<not found>}")
  fi

  # 4. claude_reply Must Fix Addressed
  if [[ "$reply_must_fix" != "Yes" ]]; then
    fail_reasons+=("claude_reply Must Fix Addressed is not Yes: ${reply_must_fix:-<not found>}")
  fi

  # 5. claude_reply Architecture Conflict Addressed
  if [[ "$reply_arch_conflict" != "Yes" ]]; then
    fail_reasons+=("claude_reply Architecture Conflict Addressed is not Yes: ${reply_arch_conflict:-<not found>}")
  fi

  # 6. claude_reply Final Recommendation
  if [[ "$reply_rec" != "PASS" ]]; then
    fail_reasons+=("claude_reply Final Recommendation is not PASS: ${reply_rec:-<not found>}")
  fi

  # 7. codex_final_review Final Recommendation
  if [[ "$final_rec" != "PASS" ]]; then
    fail_reasons+=("codex_final_review Final Recommendation is not PASS: ${final_rec:-<not found>}")
  fi

  # 8. claude_report Scope Expansion
  if [[ "$scope_expansion" != "No" ]]; then
    fail_reasons+=("claude_report Scope Expansion is not No: ${scope_expansion:-<not found>}")
  fi

  # Check for placeholder artifacts before marker evaluation.
  # Excludes codex_prompt.md (see blocking_artifacts): per consensus-workflow.md
  # Fill Artifacts Step, it is a review prompt artifact, not a review result,
  # and must not block consensus by itself.
  local -a fill_artifacts=()
  while IFS= read -r f; do
    fill_artifacts+=("$f")
  done < <(blocking_artifacts "${required[@]}")

  local -a placeholders=()
  for f in "${fill_artifacts[@]}"; do
    local fp="$round_dir/$f"
    if [[ -f "$fp" ]] && is_placeholder "$fp"; then
      placeholders+=("$f")
    fi
  done

  local gate_status
  if [[ ${#fail_reasons[@]} -eq 0 && ${#placeholders[@]} -eq 0 ]]; then
    gate_status="PASS"
  else
    gate_status="FAIL"
    if [[ ${#placeholders[@]} -gt 0 ]]; then
      fail_reasons+=("Placeholder artifacts detected (must be replaced before consensus): ${placeholders[*]}")
    fi
  fi

  # Build consensus_report.md
  local report_file="$round_dir/consensus_report.md"

  if $DRY_RUN; then
    echo "[dry-run] Would write $report_file"
    return
  fi

  {
    echo "# Consensus Report"
    echo ""
    echo "Sprint Type: $stype"
    echo ""
    echo "## Input Artifacts"
    echo ""
    for f in "${required[@]}"; do
      if [[ -f "$round_dir/$f" ]]; then
        echo "- $f: present"
      else
        echo "- $f: MISSING"
      fi
    done
    echo ""
    echo "## Deterministic Markers"
    echo ""
    echo "- codex_review Must Fix: ${must_fix:-<not found>}"
    echo "- codex_review Architecture Conflict: ${arch_conflict:-<not found>}"
    echo "- codex_review Final Recommendation: ${codex_rec:-<not found>}"
    echo "- claude_reply Must Fix Addressed: ${reply_must_fix:-<not found>}"
    echo "- claude_reply Architecture Conflict Addressed: ${reply_arch_conflict:-<not found>}"
    echo "- claude_reply Final Recommendation: ${reply_rec:-<not found>}"
    echo "- codex_final_review Final Recommendation: ${final_rec:-<not found>}"
    echo "- claude_report Scope Expansion: ${scope_expansion:-<not found>}"
    echo ""
    if [[ ${#placeholders[@]} -gt 0 ]]; then
      echo "## Placeholders Detected"
      echo ""
      for p in "${placeholders[@]}"; do
        echo "- $p: PLACEHOLDER"
      done
    fi
    echo ""
    echo "Gate Status: $gate_status"
    echo ""
    if [[ ${#fail_reasons[@]} -gt 0 ]]; then
      echo "## Fail Reasons"
      echo ""
      for r in "${fail_reasons[@]}"; do
        echo "- $r"
      done
    fi
  } > "$report_file"

  echo "Written: $report_file"
  echo "Gate Status: $gate_status"
  if [[ ${#fail_reasons[@]} -gt 0 ]]; then
    echo ""
    echo "Fail Reasons:"
    for r in "${fail_reasons[@]}"; do
      echo "  - $r"
    done
  fi
}

###############################################################################
# Command: finalize
###############################################################################

cmd_finalize() {
  local sprint_id="${1:?Usage: review_bridge.sh finalize <sprint-id> <round>}"
  shift

  local round="${1:?Usage: review_bridge.sh finalize <sprint-id> <round>}"
  shift

  parse_dry_run "$@"

  validate_id "$sprint_id" "sprint-id"
  round="$(validate_round "$round")"

  # Load Sprint Type from metadata
  load_meta "$sprint_id"
  local stype="${SPRINT_TYPE:-}"
  [[ -z "$stype" ]] && die "SPRINT_TYPE not set in sprint_meta.env"
  [[ "$stype" == "implementation" || "$stype" == "documentation" ]] \
    || die "SPRINT_TYPE must be 'implementation' or 'documentation', got: '$stype'"

  local round_dir="$REVIEWS_DIR/$sprint_id/round-$round"
  [[ -d "$round_dir" ]] || die "Round directory not found: $round_dir"

  local report_file="$round_dir/consensus_report.md"
  [[ -f "$report_file" ]] || die "consensus_report.md not found. Run 'consensus' first."

  # Read Gate Status from consensus_report.md
  local gate_status
  gate_status="$(parse_marker "$report_file" "Gate Status")"
  [[ "$gate_status" == "PASS" ]] || die "consensus_report.md Gate Status is '$gate_status', not PASS. Cannot finalize."

  # Re-parse deterministic markers for the summary in final_consensus.md
  local codex_review="$round_dir/codex_review.md"
  local claude_reply="$round_dir/claude_reply.md"
  local codex_final="$round_dir/codex_final_review.md"
  local claude_report="$round_dir/claude_report.md"

  local must_fix="" arch_conflict="" codex_rec=""
  local reply_must_fix="" reply_arch_conflict="" reply_rec=""
  local final_rec="" scope_expansion=""

  if [[ -f "$codex_review" ]]; then
    must_fix="$(parse_marker "$codex_review" "Must Fix")"
    arch_conflict="$(parse_marker "$codex_review" "Architecture Conflict")"
    codex_rec="$(parse_marker "$codex_review" "Final Recommendation")"
  fi

  if [[ -f "$claude_reply" ]]; then
    reply_must_fix="$(parse_marker "$claude_reply" "Must Fix Addressed")"
    reply_arch_conflict="$(parse_marker "$claude_reply" "Architecture Conflict Addressed")"
    reply_rec="$(parse_marker "$claude_reply" "Final Recommendation")"
  fi

  if [[ -f "$codex_final" ]]; then
    final_rec="$(parse_marker "$codex_final" "Final Recommendation")"
  fi

  if [[ -f "$claude_report" ]]; then
    scope_expansion="$(parse_marker "$claude_report" "Scope Expansion")"
  fi

  # Build final_consensus.md
  local fc_file="$round_dir/final_consensus.md"

  if $DRY_RUN; then
    echo "[dry-run] Would write $fc_file"
    return
  fi

  cat > "$fc_file" <<EOF
# Final Consensus

Sprint Type: $stype

Consensus: PASS

Consensus Stop Rule: PASS

## Deterministic Markers Summary

- codex_review Must Fix: ${must_fix:-<not found>}
- codex_review Architecture Conflict: ${arch_conflict:-<not found>}
- codex_review Final Recommendation: ${codex_rec:-<not found>}
- claude_reply Must Fix Addressed: ${reply_must_fix:-<not found>}
- claude_reply Architecture Conflict Addressed: ${reply_arch_conflict:-<not found>}
- claude_reply Final Recommendation: ${reply_rec:-<not found>}
- codex_final_review Final Recommendation: ${final_rec:-<not found>}
- claude_report Scope Expansion: ${scope_expansion:-<not found>}

## Artifacts Verified

EOF

  # List input artifacts
  local -a required=()
  case "$stype" in
    implementation)
      required=("architecture.md" "claude_report.md" "codex_prompt.md" \
                "codex_review.md" "claude_reply.md" "codex_final_review.md")
      ;;
    documentation)
      required=("reviewed_document.md" "claude_report.md" "codex_prompt.md" \
                "codex_review.md" "claude_reply.md" "codex_final_review.md")
      ;;
  esac

  for f in "${required[@]}"; do
    if [[ -f "$round_dir/$f" ]]; then
      echo "- $f: verified" >> "$fc_file"
    else
      echo "- $f: MISSING" >> "$fc_file"
    fi
  done

  echo "" >> "$fc_file"
  echo "No final_consensus.md, no commit." >> "$fc_file"

  echo "Written: $fc_file"
}

###############################################################################
# Command: notify (Sprint-013 — Generic Telegram Notification Runtime)
###############################################################################
#
# Generic, project-agnostic notification pipeline:
#   Detect Artifact -> Generate Notification Package -> Hash -> Dedup Key ->
#   Check History -> Send Telegram -> Write History (append-only)
#
# This command is purely additive: it does not read or modify sprint_meta.env,
# does not call load_meta, and does not touch check/consensus/finalize or any
# existing gate logic. It never calls Claude, Codex, git commit, or git push.

NOTIFY_ALLOWED_EVENTS=(
  claude_implementation_done
  codex_review_done
  claude_should_fix_done
  codex_final_review_done
  git_review_done
  commit_done
  push_done
  retrospective_done
)

# Notification Recipient is always Product Owner (Sprint-013 Must Fix 2):
# Telegram must never be used to notify Claude Code or Codex directly, since
# that would bypass the Product Owner Manual Gate. See
# docs/development/notification-package-specification.md Section 5.1.
NOTIFY_NOTIFICATION_RECIPIENT="Product Owner"

# Resolve deterministic per-event metadata: Next Actor (who Product Owner may
# hand the artifact to next — informational only, never auto-invoked) and the
# Product-Owner-facing Next Action text. Also doubles as the event whitelist:
# unknown events fall through to the `*` case and return 1.
# See docs/development/notification-package-specification.md Section 5.2.
NOTIFY_NEXT_ACTOR=""
NOTIFY_NEXT_STEP=""
_notify_resolve_event_meta() {
  local event_type="$1"
  case "$event_type" in
    claude_implementation_done)
      NOTIFY_NEXT_ACTOR="Codex"
      NOTIFY_NEXT_STEP="Product Owner should forward this handoff package to Codex to request an Architecture / Implementation Review."
      ;;
    codex_review_done)
      NOTIFY_NEXT_ACTOR="Product Owner"
      NOTIFY_NEXT_STEP="Product Owner should read the Codex review and decide whether to forward it to Claude Code for Must Fix / Should Fix items, or close the round."
      ;;
    claude_should_fix_done)
      NOTIFY_NEXT_ACTOR="Codex"
      NOTIFY_NEXT_STEP="Product Owner should forward this to Codex to confirm the Must Fix / Should Fix resolution and request codex_final_review.md."
      ;;
    codex_final_review_done)
      NOTIFY_NEXT_ACTOR="Product Owner"
      NOTIFY_NEXT_STEP="Product Owner should review the final result and decide on consensus / next round."
      ;;
    git_review_done)
      NOTIFY_NEXT_ACTOR="Product Owner"
      NOTIFY_NEXT_STEP="Product Owner should confirm commit scope before approving commit."
      ;;
    commit_done)
      NOTIFY_NEXT_ACTOR="Product Owner"
      NOTIFY_NEXT_STEP="Product Owner should confirm whether to proceed to push."
      ;;
    push_done)
      NOTIFY_NEXT_ACTOR="Product Owner"
      NOTIFY_NEXT_STEP="Product Owner should confirm the Sprint can be closed."
      ;;
    retrospective_done)
      NOTIFY_NEXT_ACTOR="Product Owner"
      NOTIFY_NEXT_STEP="Product Owner should record the Product Owner Decision section."
      ;;
    *)
      return 1
      ;;
  esac
  return 0
}

# Split the file at package_path (the exact, already-written Notification
# Package artifact) into <=3500-character literal chunks, written to numbered
# files under out_dir. Reads the file directly (never passes its content
# through shell variable substitution, avoiding any quoting/escaping risk).
# Character-based (not byte-based) so multi-byte text (e.g. Chinese) is never
# split mid-character. Used only so Telegram's message-length limit can be
# respected while still transmitting the artifact's own text verbatim
# (Sprint-013 Must Fix 1) — this performs no rewriting, summarizing, or
# reinterpretation of content.
_notify_split_for_telegram() {
  local package_path="$1"
  local out_dir="$2"
  python3 - "$package_path" "$out_dir" <<'PY'
import sys
package_path, out_dir = sys.argv[1], sys.argv[2]
with open(package_path, encoding="utf-8") as f:
    content = f.read()
CHUNK = 3500
chunks = [content[i:i + CHUNK] for i in range(0, len(content), CHUNK)] or [""]
for idx, chunk in enumerate(chunks):
    with open(f"{out_dir}/chunk-{idx:03d}.txt", "w", encoding="utf-8") as f:
        f.write(chunk)
PY
}

# Append one JSON line to the (project-agnostic) notification history file.
# Uses python3 for correct JSON construction (the record has 14 fields and
# free-text content; hand-rolled bash JSON escaping would be error-prone).
# Never receives TELEGRAM_BOT_TOKEN / TELEGRAM_CHAT_ID as arguments.
_notify_write_history() {
  local history_file="$1"; shift
  python3 - "$history_file" "$@" <<'PY'
import json
import sys

(history_file, project_id, project_name, sprint_id, round_id, event_type,
 artifact_path, artifact_hash, notification_package_path, delivery_channel,
 delivery_status, deduplication_key, created_at, delivered_at,
 error_message) = sys.argv[1:16]

record = {
    "project_id": project_id,
    "project_name": project_name,
    "sprint_id": sprint_id,
    "round_id": round_id,
    "event_type": event_type,
    "artifact_path": artifact_path,
    "artifact_hash": artifact_hash,
    "notification_package_path": notification_package_path,
    "delivery_channel": delivery_channel,
    "delivery_status": delivery_status,
    "deduplication_key": deduplication_key,
    "created_at": created_at,
    "delivered_at": delivered_at or None,
    "error_message": error_message or None,
}

with open(history_file, "a", encoding="utf-8") as f:
    f.write(json.dumps(record, ensure_ascii=False) + "\n")
PY
}

# Return 0 (true) if a `delivered` record already exists for this
# deduplication key. Reads reviews/notification_history.jsonl only; no
# Database. Malformed lines are skipped rather than aborting the scan.
_notify_already_delivered() {
  local history_file="$1"
  local dedup_key="$2"
  [[ -f "$history_file" ]] || return 1
  python3 - "$history_file" "$dedup_key" <<'PY'
import json
import sys

history_file, dedup_key = sys.argv[1], sys.argv[2]
found = False
with open(history_file, encoding="utf-8") as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            record = json.loads(line)
        except json.JSONDecodeError:
            continue
        if record.get("deduplication_key") == dedup_key and record.get("delivery_status") == "delivered":
            found = True
sys.exit(0 if found else 1)
PY
}

cmd_notify() {
  local sprint_id="${1:?Usage: review_bridge.sh notify <sprint-id> <round> <event-type> <artifact-path>}"
  shift
  local round="${1:?Usage: review_bridge.sh notify <sprint-id> <round> <event-type> <artifact-path>}"
  shift
  local event_type="${1:?Usage: review_bridge.sh notify <sprint-id> <round> <event-type> <artifact-path>}"
  shift
  local artifact_path="${1:?Usage: review_bridge.sh notify <sprint-id> <round> <event-type> <artifact-path>}"
  shift

  parse_dry_run "$@"

  validate_id "$sprint_id" "sprint-id"
  round="$(validate_round "$round")"
  local round_id="round-$round"

  if [[ "$artifact_path" == *".."* ]]; then
    die "Invalid artifact-path: '$artifact_path' (contains forbidden characters)"
  fi

  if ! _notify_resolve_event_meta "$event_type"; then
    die "Invalid event_type: '$event_type'. Allowed: ${NOTIFY_ALLOWED_EVENTS[*]}"
  fi

  local project_id="${PROJECT_ID:-}"
  local project_name="${PROJECT_NAME:-}"
  [[ -z "$project_id" ]] && die "PROJECT_ID environment variable is required (no default is assumed)"
  [[ -z "$project_name" ]] && die "PROJECT_NAME environment variable is required (no default is assumed)"

  local history_file="$REVIEWS_DIR/notification_history.jsonl"

  local abs_artifact_path
  if [[ "$artifact_path" = /* ]]; then
    abs_artifact_path="$artifact_path"
  else
    abs_artifact_path="$REPO_ROOT/$artifact_path"
  fi

  local created_at
  created_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  if [[ ! -f "$abs_artifact_path" ]]; then
    if ! $DRY_RUN; then
      _notify_write_history "$history_file" \
        "$project_id" "$project_name" "$sprint_id" "$round_id" "$event_type" \
        "$artifact_path" "" "" "telegram" "failed" "" "$created_at" "" \
        "Artifact not found: $artifact_path"
    fi
    die "Artifact not found: $artifact_path"
  fi

  local artifact_hash
  artifact_hash="$(sha256sum "$abs_artifact_path" | awk '{print $1}')"

  local dedup_key="${project_id}/${sprint_id}/${round_id}/${event_type}/${artifact_path}/${artifact_hash}"

  local notif_dir="$REVIEWS_DIR/$sprint_id/round-$round/notifications"
  local notif_path="$notif_dir/${event_type}.md"

  if $DRY_RUN; then
    echo "[dry-run] Would write $notif_path"
    echo "[dry-run] Deduplication key: $dedup_key"
    echo "[dry-run] Would check $history_file for an existing 'delivered' record"
    echo "[dry-run] Would POST to Telegram Bot API if NOTIFICATION_ENABLED=true and config is present"
    return 0
  fi

  mkdir -p "$notif_dir"

  # Copyable Handoff Package: framed from Product Owner's perspective (the
  # recipient), to be forwarded by Product Owner to NOTIFY_NEXT_ACTOR — never
  # phrased as an instruction addressed directly to that actor (Must Fix 2).
  local copyable_prompt
  copyable_prompt="$(cat <<EOF
請閱讀：
- ${artifact_path}

Sprint: ${sprint_id}
Round: ${round_id}
Event: ${event_type}
Next Actor（若 Product Owner 決定轉交）: ${NOTIFY_NEXT_ACTOR}

${NOTIFY_NEXT_STEP}
EOF
)"

  # Notification Package: the sole content source for delivery (Must Fix 1).
  # Field set matches docs/development/notification-package-specification.md
  # Section 3 exactly (17 fields). Delivery Status is recorded here only as
  # "pending" (the state as of generation time, before any send is
  # attempted) — the authoritative post-attempt outcome is written to
  # Notification History below, never mutated back into this file, so the
  # text actually transmitted to Telegram is never retroactively different
  # from what is later read from disk.
  cat > "$notif_path" <<EOF
# Notification Package

## Project ID

${project_id}

## Project Name

${project_name}

## Sprint ID

${sprint_id}

## Round ID

${round_id}

## Event Type

${event_type}

## Notification Recipient

${NOTIFY_NOTIFICATION_RECIPIENT}

## Next Actor

${NOTIFY_NEXT_ACTOR}

## Source Artifact Path

${artifact_path}

## Artifact Hash

${artifact_hash}

## Deduplication Key

${dedup_key}

## Notification Package Path

${notif_path}

## Delivery Channel

telegram

## Delivery Status

pending

## Created Time

${created_at}

## Product Owner Next Action

${NOTIFY_NEXT_STEP}

## Copyable Handoff Package

${copyable_prompt}

## Delivery Metadata

- Delivery Channel: telegram
- Deduplication Key: ${dedup_key}
- Created At: ${created_at}
EOF

  echo "Written: $notif_path"

  if _notify_already_delivered "$history_file" "$dedup_key"; then
    _notify_write_history "$history_file" \
      "$project_id" "$project_name" "$sprint_id" "$round_id" "$event_type" \
      "$artifact_path" "$artifact_hash" "$notif_path" "telegram" \
      "skipped_duplicate" "$dedup_key" "$created_at" "" ""
    echo "skipped_duplicate: this artifact/event/hash combination was already delivered."
    return 0
  fi

  local delivery_status delivered_at error_message
  delivered_at=""
  error_message=""

  if [[ "${NOTIFICATION_ENABLED:-}" != "true" ]]; then
    delivery_status="disabled"
    echo "Telegram delivery disabled (NOTIFICATION_ENABLED is not 'true')."
  elif [[ -z "${TELEGRAM_BOT_TOKEN:-}" || -z "${TELEGRAM_CHAT_ID:-}" ]]; then
    delivery_status="disabled"
    echo "Telegram delivery disabled (TELEGRAM_BOT_TOKEN or TELEGRAM_CHAT_ID is not set)."
  elif ! command -v curl >/dev/null 2>&1; then
    delivery_status="failed"
    error_message="curl is not installed"
    echo "WARNING: curl is not installed; cannot deliver to Telegram." >&2
  else
    # Sprint-013 Must Fix 1: send the Notification Package artifact's own
    # text, unmodified. No separate message is composed. If the artifact
    # exceeds Telegram's message-length limit, it is split into literal
    # chunks (never rewritten/summarized) and sent as consecutive messages.
    local chunk_dir
    chunk_dir="$(mktemp -d)"
    _notify_split_for_telegram "$notif_path" "$chunk_dir"

    local all_ok=true
    local any_attempted=false
    local chunk_file
    for chunk_file in "$chunk_dir"/chunk-*.txt; do
      [[ -f "$chunk_file" ]] || continue
      any_attempted=true
      local telegram_url="https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage"
      local response
      if response="$(curl -fsS --max-time 5 -X POST "$telegram_url" \
            --data-urlencode "chat_id=${TELEGRAM_CHAT_ID}" \
            --data-urlencode "text@${chunk_file}" 2>/dev/null)"; then
        echo "$response" | grep -q '"ok":true' || all_ok=false
      else
        all_ok=false
      fi
    done
    rm -rf "$chunk_dir"

    if ! $any_attempted; then
      delivery_status="failed"
      error_message="No message chunks were produced from the Notification Package"
      echo "WARNING: Telegram delivery produced no chunks to send. Continuing without blocking the workflow." >&2
    elif $all_ok; then
      delivery_status="delivered"
      delivered_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
      echo "Telegram delivery: delivered (Notification Package artifact sent verbatim)."
    else
      delivery_status="failed"
      error_message="Telegram API request failed for at least one message chunk"
      echo "WARNING: Telegram API request failed. Continuing without blocking the workflow." >&2
    fi
  fi

  _notify_write_history "$history_file" \
    "$project_id" "$project_name" "$sprint_id" "$round_id" "$event_type" \
    "$artifact_path" "$artifact_hash" "$notif_path" "telegram" \
    "$delivery_status" "$dedup_key" "$created_at" "$delivered_at" "$error_message"

  echo "Notification history updated: $history_file (delivery_status=$delivery_status)"
  return 0
}

###############################################################################
# Main dispatcher
###############################################################################

[[ $# -lt 1 ]] && usage

COMMAND="$1"
shift

case "$COMMAND" in
  init)                  cmd_init "$@" ;;
  skeleton)              cmd_skeleton "$@" ;;
  check)                 cmd_check "$@" ;;
  validate-final-consensus) cmd_validate_final_consensus "$@" ;;
  consensus)             cmd_consensus "$@" ;;
  finalize)              cmd_finalize "$@" ;;
  notify)                cmd_notify "$@" ;;
  *)                     die_usage "Unknown command: '$COMMAND'." ;;
esac
