#!/usr/bin/env bash
# OmniRoute install + start.
# Usage: INITIAL_PASSWORD='StrongPass123!' ./setup-omniroute.sh
set -euo pipefail

PORT="${PORT:-20128}"
PASS="${INITIAL_PASSWORD:-}"

say() { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
die() { printf '\033[1;31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }

command -v node >/dev/null || die "Node.js install karo"
command -v npm  >/dev/null || die "npm install karo"

NODE_VER="$(node -p 'process.versions.node')"
node -e '
const [maj,min,pat] = process.versions.node.split(".").map(Number);
const ok = (maj===20 && (min>20 || (min===20 && pat>=2))) ||
           (maj===22 && (min>22 || (min===22 && pat>=2))) ||
           (maj>=24 && maj<=26);
process.exit(ok?0:1);
' || die "OmniRoute ko Node 22.22.2+ ya 24 LTS chahiye (mila: $NODE_VER). nvm use 24"

if [ -z "$PASS" ]; then
  die "INITIAL_PASSWORD set karo, e.g. INITIAL_PASSWORD='StrongPass123!' ./setup-omniroute.sh"
fi

if ! command -v omniroute >/dev/null; then
  say "npm install -g omniroute (bara package, 5-20 min)"
  npm install -g omniroute --no-audit --no-fund
fi

if curl -fsS -m 2 "http://127.0.0.1:${PORT}/" >/dev/null 2>&1; then
  say "OmniRoute pehle se chal raha hai: http://localhost:${PORT}"
  exit 0
fi

say "Server start (log: /tmp/omniroute.log)"
setsid env INITIAL_PASSWORD="$PASS" omniroute --no-open --port "$PORT" \
  < /dev/null > /tmp/omniroute.log 2>&1 &
disown

for i in $(seq 1 45); do
  sleep 2
  if curl -fsS -m 2 "http://127.0.0.1:${PORT}/api/init" >/dev/null 2>&1; then
    say "Ready: http://localhost:${PORT}"
    say "Login password: (jo INITIAL_PASSWORD diya)"
    say "Dashboard -> Providers (free provider add) -> Endpoints (API key banao)"
    exit 0
  fi
done

echo "--- last log ---"
tail -25 /tmp/omniroute.log
die "Server start nahi hua. Upar ka log dekho."
