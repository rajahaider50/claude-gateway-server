#!/usr/bin/env bash
# Dono gateways band karo (data delete nahi hota).
set -uo pipefail
say() { printf '\033[1;36m==>\033[0m %s\n' "$*"; }

if pgrep -f "server/src/index.ts" >/dev/null 2>&1; then
  pkill -f "server/src/index.ts" && say "FreeLLMAPI stopped"
fi

if pgrep -f "omniroute[.]mjs" >/dev/null 2>&1; then
  pkill -f "omniroute[.]mjs" && say "OmniRoute stopped"
fi

say "Done. (Claude Code config ~/.claude/settings.json mein hai; chaho to backup restore karo)"
