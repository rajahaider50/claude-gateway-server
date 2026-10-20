#!/usr/bin/env bash
# FreeLLMAPI install + start (no Docker).
# Usage: ./setup-freellmapi.sh [install-dir]
set -euo pipefail

DIR="${1:-$HOME/freellmapi}"
PORT="${PORT:-3001}"

say() { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
die() { printf '\033[1;31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }

command -v node >/dev/null || die "Node.js install karo (>=20)"
command -v git  >/dev/null || die "git install karo"

NODE_MAJOR="$(node -p 'process.versions.node.split(".")[0]')"
[ "$NODE_MAJOR" -ge 20 ] || die "Node >= 20 chahiye (mila: $(node -v))"

if [ ! -d "$DIR/.git" ]; then
  say "Cloning FreeLLMAPI -> $DIR"
  git clone --depth 1 https://github.com/tashfeenahmed/freellmapi.git "$DIR"
fi

cd "$DIR"

if [ ! -d node_modules ]; then
  say "npm install (5-15 min lag sakte hain)"
  npm install --no-audit --no-fund
fi

if [ ! -f .env ]; then
  say ".env bana rahe hain (ENCRYPTION_KEY generate)"
  {
    printf 'ENCRYPTION_KEY=%s\n' "$(node -e 'console.log(require("crypto").randomBytes(32).toString("hex"))')"
    printf 'PORT=%s\n' "$PORT"
  } > .env
  chmod 600 .env
fi

if curl -fsS -m 2 "http://127.0.0.1:${PORT}/api/ping" >/dev/null 2>&1; then
  say "FreeLLMAPI pehle se chal raha hai: http://localhost:${PORT}"
  exit 0
fi

say "Server start kar rahe hain (log: /tmp/freellmapi.log)"
setsid node --import tsx/esm server/src/index.ts < /dev/null > /tmp/freellmapi.log 2>&1 &
disown

for i in $(seq 1 45); do
  sleep 2
  if curl -fsS -m 2 "http://127.0.0.1:${PORT}/api/ping" >/dev/null 2>&1; then
    say "Ready: http://localhost:${PORT}"
    say "Dashboard kholo -> account banao -> Keys page -> provider key + unified key"
    say "Unified key logs mein nahi hoti; dashboard ke Keys page se copy karo."
    exit 0
  fi
done

echo "--- last log ---"
tail -20 /tmp/freellmapi.log
die "Server start nahi hua. Upar ka log dekho."
