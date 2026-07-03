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
  *)                     die_usage "Unknown command: '$COMMAND'." ;;
esac
