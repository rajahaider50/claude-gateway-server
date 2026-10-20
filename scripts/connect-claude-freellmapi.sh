#!/usr/bin/env bash
# FreeLLMAPI -> Claude Code
# Usage: ./connect-claude-freellmapi.sh [base-url] [unified-key] [model]
set -euo pipefail
BASE="${1:-http://localhost:3001}"
KEY="${2:-${FREELLMAPI_KEY:-}}"
MODEL="${3:-auto}"
HERE="$(cd "$(dirname "$0")" && pwd)"
[ -n "$KEY" ] || { echo "Usage: $0 [base] <unified-key> [model]"; exit 1; }
exec "$HERE/connect-claude.sh" "$BASE" "$KEY" "$MODEL" --test
