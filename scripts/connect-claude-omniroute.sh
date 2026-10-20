#!/usr/bin/env bash
# OmniRoute -> Claude Code
# Usage: ./connect-claude-omniroute.sh [base-url] [sk-key] [model]
set -euo pipefail
BASE="${1:-http://localhost:20128}"
KEY="${2:-${OMNIROUTE_KEY:-}}"
MODEL="${3:-auto}"
HERE="$(cd "$(dirname "$0")" && pwd)"
[ -n "$KEY" ] || { echo "Usage: $0 [base] <sk-key> [model]"; exit 1; }
exec "$HERE/connect-claude.sh" "$BASE" "$KEY" "$MODEL" --test
