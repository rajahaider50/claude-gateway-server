# Test Report — 20 Oct 2026

Environment: Linux arm64, Node 20.20.2 (FreeLLMAPI) + Node 22.22.0 (OmniRoute),
Claude Code 2.1.197. No Docker available, so npm/local installs were tested.

---

## A. FreeLLMAPI — PASS

Install:

```bash
git clone https://github.com/tashfeenahmed/freellmapi.git
npm install                       # 840 packages
printf "ENCRYPTION_KEY=%s\nPORT=3001\n" "$(openssl rand -hex 32)" > .env
node --import tsx/esm server/src/index.ts
```

Provider setup: OVH, Kilo, AI Horde added as keyless connections (no signup).

```
GET  /v1/models              -> 200, 278 models (60 available)
POST /v1/chat/completions    -> 200  content="OPENAI_WIRE"  (provider: nvidia via Kilo)
POST /v1/messages            -> 200  content="CLAUDE_WIRE_OK" (Anthropic SDK)
```

Claude Code:

```
$ claude -p "Say OK"
OK

$ claude -p "Use the Write tool to create /tmp/claude-gateway-test.txt ..."
Created `/tmp/claude-gateway-test.txt` containing exactly `hello-from-gateway`.
$ cat /tmp/claude-gateway-test.txt
hello-from-gateway
```

DB proof (`server/data/freeapi.db`, table `requests`):

```
platform=kilo  model=dots-studio/dots-3-note-preview:free  status=success
platform=ovh   model=Meta-Llama-3_3-70B-Instruct           status=success
client_user_agent=claude-cli/2.1.197 (external, sdk-cli)
```

Final smoke test (`scripts/test-all.sh`):

```
PASS  GET /v1/models — HTTP 200, 278 models
PASS  POST /v1/chat/completions — HTTP 200 — OPENAI_WIRE
PASS  POST /v1/messages (Anthropic) — HTTP 200 — CLAUDE_WIRE_OK
ALL CHECKS PASSED
```

---

## B. OmniRoute — PASS (with free-tier caveat)

Install and start:

```bash
npm install -g omniroute
INITIAL_PASSWORD='StrongPass123!' omniroute --no-open --port 20128
```

Login: `POST /api/auth/login {"password":"..."}` → `{"success":true}`
API key: `POST /api/keys {"name":"claude-code"}` → `sk-...`
Provider: `POST /api/providers {"provider":"pollinations","name":"pollinations","apiKey":"no-key"}`

Anthropic wire:

```
POST /v1/messages -> 200
event: message_start
data: {"type":"message_start", ... "model":"gpt-oss-20b" ...}
event: content_block_delta
data: {"type":"content_block_delta","delta":{"type":"thinking_delta","thinking":"User"}}
```

Claude Code end-to-end (FreeLLMAPI temporarily stopped, to prove the request went to :20128):

```
$ claude -p "Say OMNIROUTE_ONLY_OK and nothing else"
OMNIROUTE_ONLY_OK
```

OmniRoute `call_logs` proof:

```
2026-10-20T12:42:16.558Z  /v1/messages  200  provider=pollinations  tokens_in=17803  tokens_out=362
2026-10-20T12:42:03.997Z  /v1/messages  200  provider=pollinations  tokens_in=429    tokens_out=1500
```

After a few requests the free keyless tier returned:

```
HTTP 402: Free limit reached: 1 reply every 30 seconds per IP.
```

and the connection was marked `credits_exhausted`, after which requests answered
`No credentials for provider: pollinations`. This is an upstream free-tier limit, not a
config bug. **Fix: add a real free key (Groq / Cerebras / Google AI Studio) in Providers.**

---

## C. Problems hit during testing (and fixes)

| Symptom | Root cause | Fix |
|---|---|---|
| `better-sqlite3` → `NODE_MODULE_VERSION 115 vs 127` | native module built for another Node major | `npm rebuild better-sqlite3` under the same Node that runs the server |
| `libdl.so: cannot open shared object file` | build used the wrong libc toolchain | rebuild with the distro toolchain (`CC=gcc CXX=g++ ...`) — Windows/macOS users won't see this |
| OmniRoute `e.util.markAsUncloneable is not a function` | bundled undici expects a newer Node `util` API | run OmniRoute on Node 22.22.2+ / 24 LTS |
| OmniRoute `EADDRINUSE :20128` | stale process | `pkill -f "omniroute[.]mjs"` |
| OmniRoute login `No password configured` | first boot had no `INITIAL_PASSWORD` | start once with `INITIAL_PASSWORD=... omniroute` |
| `auto` → `No credentials for provider: openrouter` | no eligible connection / default combo | add provider or use explicit model id |
| Claude Code ignored `ANTHROPIC_BASE_URL` env | `~/.claude/settings.json` `env` block overrides shell env | edit settings.json or use the connect script |
| Root `--dangerously-skip-permissions` refused | Anthropic blocks it as root | `--permission-mode acceptEdits` |

---

## D. What was NOT possible

- **claude.ai (web)** cannot be pointed at a custom base URL. No workaround exists;
  Anthropic does not expose that setting. Use Claude Code (CLI) or Claude Desktop + MCP.
- Claude Desktop cannot use these gateways as its *model*, only their MCP tools.
- Keyless providers are for smoke tests, not daily use — always add your own free keys.
