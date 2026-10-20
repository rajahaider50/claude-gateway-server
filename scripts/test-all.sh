#!/usr/bin/env bash
# Dono gateways test karta hai (jo chal rahe hain).
# Usage:
#   FREELLMAPI_KEY=freellmapi-... OMNIROUTE_KEY=sk-... ./test-all.sh
#   FREELLMAPI_MODEL=auto OMNIROUTE_MODEL=pol/openai ./test-all.sh
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
FAIL=0

if [ -n "${FREELLMAPI_KEY:-}" ]; then
  echo "=== FreeLLMAPI (${FREELLMAPI_BASE:-http://127.0.0.1:3001}) ==="
  node "$HERE/test-gateway.mjs" "${FREELLMAPI_BASE:-http://127.0.0.1:3001}" "$FREELLMAPI_KEY" "${FREELLMAPI_MODEL:-auto}" || FAIL=1
else
  echo "SKIP  FreeLLMAPI (FREELLMAPI_KEY set nahi hai)"
fi

echo

if [ -n "${OMNIROUTE_KEY:-}" ]; then
  echo "=== OmniRoute (${OMNIROUTE_BASE:-http://127.0.0.1:20128}) ==="
  node "$HERE/test-gateway.mjs" "${OMNIROUTE_BASE:-http://127.0.0.1:20128}" "$OMNIROUTE_KEY" "${OMNIROUTE_MODEL:-auto}" || FAIL=1
else
  echo "SKIP  OmniRoute (OMNIROUTE_KEY set nahi hai)"
fi

exit "$FAIL"
