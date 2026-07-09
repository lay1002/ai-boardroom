#!/usr/bin/env bash
# test_approved_execution_queue.sh — thin wrapper around the Python test
# suite for scripts/approved_execution_queue.py (Sprint-019).
#
# Usage: bash scripts/test_approved_execution_queue.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

exec python3 "$SCRIPT_DIR/test_approved_execution_queue.py" "$@"
