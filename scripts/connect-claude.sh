#!/usr/bin/env bash
# Claude Code ko kisi bhi Anthropic-compatible gateway se connect karta hai.
# Usage: ./connect-claude.sh <base-url> <api-key> [model] [--test]
# Example: ./connect-claude.sh http://localhost:3001 freellmapi-abc auto --test
set -euo pipefail

BASE="${1:-}"; KEY="${2:-}"; MODEL="${3:-auto}"; TEST="${4:-}"

say() { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
die() { printf '\033[1;31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }

[ -n "$BASE" ] && [ -n "$KEY" ] || die "Usage: $0 <base-url> <api-key> [model] [--test]"
BASE="${BASE%/}"
BASE="${BASE%/v1}"          # Claude Code ko ROOT chahiye, /v1 nahi

command -v claude >/dev/null || die "Claude Code install karo: npm i -g @anthropic-ai/claude-code"

CFG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
mkdir -p "$CFG_DIR"
CFG="$CFG_DIR/settings.json"

if [ -f "$CFG" ]; then
  BAK="$CFG.bak-$(date +%Y%m%d-%H%M%S)"
  cp "$CFG" "$BAK"
  say "Backup: $BAK"
fi

BASE="$BASE" KEY="$KEY" MODEL="$MODEL" CFG="$CFG" node <<'NODE'
const fs = require('fs');
const cfgPath = process.env.CFG;
let cfg = {};
try { cfg = JSON.parse(fs.readFileSync(cfgPath, 'utf8')); } catch {}
cfg.env = cfg.env || {};
Object.assign(cfg.env, {
  ANTHROPIC_BASE_URL: process.env.BASE,
  ANTHROPIC_AUTH_TOKEN: process.env.KEY,
  ANTHROPIC_MODEL: process.env.MODEL,
  ANTHROPIC_DEFAULT_OPUS_MODEL: process.env.MODEL,
  ANTHROPIC_DEFAULT_SONNET_MODEL: process.env.MODEL,
  ANTHROPIC_DEFAULT_HAIKU_MODEL: process.env.MODEL,
});
fs.writeFileSync(cfgPath, JSON.stringify(cfg, null, 2) + '\n', { mode: 0o600 });
console.log('Wrote ' + cfgPath);
NODE

say "Claude Code ab is gateway par chalega: $BASE (model: $MODEL)"
say "Note: settings.json ka env shell ke ANTHROPIC_* vars ko override karta hai."

if [ "$TEST" = "--test" ]; then
  say "Live test: claude -p ..."
  timeout 180 claude -p "Reply with exactly: CLAUDE_GATEWAY_OK" --output-format text
fi
