# Claude AI + Free LLM Gateways — Full Setup (OmniRoute + FreeLLMAPI)

> **Tested:** 20 Oct 2026 · Claude Code `2.1.197` · FreeLLMAPI `0.2.1` · OmniRoute `3.7.9`
> **Result:** ✅ Dono gateways se Claude Code live chala — including tool use (file write).

---

## 0. One command (recommended)

```bash
git clone https://github.com/rajahaider50/claude-gateway-server.git
cd claude-gateway-server
./server start
```

Pehli baar ye khud hi:

1. FreeLLMAPI clone + `npm install` + build karta hai
2. OmniRoute install karta hai (agar missing ho)
3. Strong secrets generate karta hai (`~/.claude-gateway/secrets.env`, chmod 600)
4. Dono ko **sirf 127.0.0.1** par start karta hai (LAN/internet se accessible nahi)
5. Health check karke dashboard URLs print karta hai

```bash
./server status                 # dono ke PID + health
./server logs omniroute -f      # live logs
./server test                   # models + OpenAI + Anthropic wire tests
./server connect freellmapi     # Claude Code ko gateway se jodo
./server stop                   # dono band
./server doctor                 # environment diagnose
```

Sab kuch `~/.claude-gateway/` mein rehta hai — uninstall ke liye wahi folder delete karo.

---

## 1. Pehle ye samajh lo (important)

Aap ne `claude.ai/new` ka link diya. Us **website** ko kisi third-party API se connect
**nahi** kiya ja sakta — Anthropic apni web app mein custom base URL allow nahi karta.

Lekin "Claude AI" ke 2 official raste hain jo kaam karte hain:

| Rasta | Custom API? | Kya chahiye | Best for |
|---|---|---|---|
| **Claude Code (CLI)** | ✅ Haan (`ANTHROPIC_BASE_URL`) | Node 18+, terminal | Coding, files, agents |
| **Claude Desktop** | ⚠️ Sirf MCP ke through | MCP server | Chat + tools |
| claude.ai (website) | ❌ Nahi | — | — |

Dono gateways (OmniRoute, FreeLLMAPI) **Anthropic Messages wire** (`POST /v1/messages`)
support karte hain, is liye Claude Code inke saath directly chalta hai.

**Claude Code ka base URL = gateway ka ROOT** (e.g. `http://localhost:3001`), `/v1` **nahi** —
kyunki Claude Code khud `/v1/messages` append karta hai.

---

## 2. Kaunsa gateway choose karun?

| | **FreeLLMAPI** | **OmniRoute** |
|---|---|---|
| Port | `3001` | `20128` |
| Install | Docker / git+npm / desktop app | `npm i -g omniroute` |
| Node | 20+ | **22.22.2+ / 24 LTS** (Next.js 16) |
| Providers | 34 (635 endpoints) | 375 providers |
| Claude Code | `npx freellmapi setup-claude` | `omniroute setup-claude` |
| Keyless free providers | OVH, Kilo, AI Horde | Pollinations (verified), + others |
| Extra | Response cache, compression, MCP | Combos, 20 routing strategies, compression |
| Dashboard | `localhost:3001` | `localhost:20128` |
| Auth | First-run account + unified key | `INITIAL_PASSWORD` + API key |

Dono free hain, dono ko saath bhi chala sakte ho (alag ports). Start with **FreeLLMAPI**
(simpler), OmniRoute tab use karo jab multi-provider routing/fallback chahiye.

---

## 3. Test results (jo maine actually chalaye)

```
FreeLLMAPI  :3001
  GET  /v1/models                -> 200, 278 models (OVH + Kilo keyless)
  POST /v1/chat/completions      -> 200  OPENAI_WIRE
  POST /v1/messages (Anthropic)  -> 200  CLAUDE_WIRE_OK
  claude -p "Say OK"             -> "OK"
  claude -p "write file..."      -> ✅ /tmp/claude-gateway-test.txt created

OmniRoute   :20128
  POST /v1/messages (Anthropic)  -> 200 SSE (gpt-oss-20b via Pollinations)
  claude -p "..."                -> "OMNIROUTE_ONLY_OK"
  call_logs: /v1/messages 200, provider=pollinations, in=17803 out=362
```

**Reality check:** keyless providers par free limit jaldi lag jati hai. Pollinations
sirf **1 reply / 30 sec per IP** deta hai aur limit ke baad OmniRoute connection ko
`credits_exhausted` mark kar deta hai (`No credentials for provider: pollinations`).
Is liye OmniRoute par ek real free key (Groq / Cerebras / Gemini) add karna zaroori hai.
FreeLLMAPI ka OVH/Kilo keyless quota test ke liye kaafi tha.

Detailed evidence: [`TEST-REPORT.md`](./TEST-REPORT.md)

---

## 4. Setup A — FreeLLMAPI (recommended first)

### 4.1 Install (Docker — sab se aasan)

```bash
curl -fsSL https://freellmapi.co/install.sh | bash
# Dashboard: http://localhost:3001
```

Ya repo se:

```bash
git clone https://github.com/tashfeenahmed/freellmapi.git
cd freellmapi
echo "ENCRYPTION_KEY=$(openssl rand -hex 32)" > .env
echo "PORT=3001" >> .env
docker compose up -d
```

### 4.2 Install (npm / no Docker — jo maine test kiya)

```bash
git clone https://github.com/tashfeenahmed/freellmapi.git
cd freellmapi
npm install

# .env (repo root)
printf "ENCRYPTION_KEY=%s\nPORT=3001\n" \
  "$(node -e 'console.log(require("crypto").randomBytes(32).toString("hex"))')" > .env

# start (dev mode, no build needed)
npm run dev -w server
```

Server logs mein pehli baar:
- **Unified API key** generate hota hai (logs mein print **nahi** hota — dashboard se lo)
- **First-run setup code** print hota hai (agar remote se dashboard kholna ho)

Dashboard `http://localhost:3001` kholo → account banao → **Keys** page:
1. Apne free provider keys add karo (Groq / Cerebras / Google AI Studio / OpenRouter :free).
2. Header se **unified key** copy karo (`freellmapi-...`).
3. Fallback Chain order set karo.

> Keyless test ke liye: OVH, Kilo, AI Horde bina key add ho jate hain (dashboard → Keys).
> Maine inhi se test kiya.

### 4.3 Test (CLI se)

```bash
KEY="freellmapi-xxxxxxxx"   # apni unified key

# models
curl -s http://localhost:3001/v1/models -H "Authorization: Bearer $KEY" | head -c 300

# OpenAI wire
curl -s http://localhost:3001/v1/chat/completions \
  -H "Authorization: Bearer $KEY" -H 'Content-Type: application/json' \
  -d '{"model":"auto","messages":[{"role":"user","content":"Say OK"}],"max_tokens":20}'

# Anthropic wire (jo Claude Code use karta hai)
curl -s http://localhost:3001/v1/messages \
  -H "x-api-key: $KEY" -H 'anthropic-version: 2023-06-01' \
  -H 'Content-Type: application/json' \
  -d '{"model":"auto","max_tokens":20,"messages":[{"role":"user","content":"Say OK"}]}'
```

### 4.4 Claude Code connect

```bash
npm i -g @anthropic-ai/claude-code

npx freellmapi setup-claude --url http://localhost:3001 --api-key "$KEY" --dry-run
npx freellmapi setup-claude --url http://localhost:3001 --api-key "$KEY"
```

Ye `~/.claude/settings.json` likhta hai (backup ke saath). Phir:

```bash
claude -p "Say OK"
claude          # interactive
```

Manual config (agar CLI na chale) — `~/.claude/settings.json`:

```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "http://localhost:3001",
    "ANTHROPIC_AUTH_TOKEN": "freellmapi-YOUR-KEY",
    "ANTHROPIC_MODEL": "auto",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "auto",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "auto",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "auto"
  }
}
```

---

## 5. Setup B — OmniRoute

### 5.1 Node 22.22.2+ / 24 LTS chahiye

```bash
node -v    # v22.22.2+ ya v24.x hona chahiye
```

Node purana ho to nvm:

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
nvm install 24 && nvm use 24
```

### 5.2 Install & start

```bash
npm install -g omniroute

# PEHLI BAAR: dashboard password set karo
INITIAL_PASSWORD='YourStrongPassword123!' omniroute --no-open --port 20128
```

> npm package ke `.env` mein `INITIAL_PASSWORD=CHANGEME` hota hai. Pehli boot par
> env var se pass karo, warna login "No password configured" deta hai.

Dashboard: `http://localhost:20128` → login.

### 5.3 Provider + API key

1. **Providers** → free provider add karo (Pollinations keyless hai — turant kaam karta hai;
   Groq/Cerebras/Google keys better hain).
2. **Endpoints** → **API key create** karo (`sk-...`).
3. Test:

```bash
OKEY="sk-xxxxxxxx"
curl -s http://localhost:20128/v1/models -H "Authorization: Bearer $OKEY" | head -c 300

curl -s http://localhost:20128/v1/messages \
  -H "x-api-key: $OKEY" -H 'anthropic-version: 2023-06-01' \
  -H 'Content-Type: application/json' \
  -d '{"model":"auto","max_tokens":20,"messages":[{"role":"user","content":"Say OK"}]}'
```

> `model: auto` ke liye kam se kam ek eligible connection chahiye. Fresh install par
> `auto` "No credentials for provider: openrouter" de sakta hai — tab provider/model
> explicitly do (e.g. `pol/openai`, `groq/llama-3.3-70b-versatile`).

### 5.4 Claude Code connect

```bash
omniroute setup-claude --help          # options dekho
omniroute setup-claude --dry-run
omniroute setup-claude                 # ~/.claude/settings.json likhta hai
```

Manual:

```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "http://localhost:20128",
    "ANTHROPIC_AUTH_TOKEN": "sk-YOUR-OMNIROUTE-KEY",
    "ANTHROPIC_MODEL": "auto",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "auto",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "auto",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "auto"
  }
}
```

Phir `claude -p "Say OK"`.

---

## 6. Dono saath + switch karna

Dono alag ports par chal sakte hain. Claude Code ek waqt mein ek config use karta hai.

**Sab se important discovery:** `~/.claude/settings.json` ka `env` block shell env vars ko
**override** karta hai. Is liye `ANTHROPIC_BASE_URL=... claude` karke gateway badalne ki
koshish kaam nahi karti — file edit karni padti hai.

Profile scripts:

```bash
cp ~/.claude/settings.json ~/.claude/settings.freellmapi.json
cp ~/.claude/settings.omniroute.json ~/.claude/settings.json   # switch
```

Ya repo ke scripts:

```bash
./scripts/connect-claude-freellmapi.sh http://localhost:3001 freellmapi-KEY
./scripts/connect-claude-omniroute.sh   http://localhost:20128 sk-KEY
```

Har script pehle backup banata hai (`settings.json.bak-<timestamp>`).

---

## 7. Claude Desktop (MCP option)

Claude Desktop custom API base URL support nahi karta, lekin MCP servers se baat kar sakta hai.

### OmniRoute MCP

```bash
omniroute --mcp     # stdio transport
```

`claude_desktop_config.json` (macOS: `~/Library/Application Support/Claude/`,
Windows: `%APPDATA%\Claude\`):

```json
{
  "mcpServers": {
    "omniroute": {
      "command": "npx",
      "args": ["-y", "omniroute", "--mcp"]
    }
  }
}
```

### FreeLLMAPI MCP (HTTP)

Pehle MCP surface on karo (dashboard → Keys → Agent compatibility, ya):

```bash
curl -X PUT http://localhost:3001/api/settings/enable-mcp \
  -H "Authorization: Bearer <dashboard-token>" \
  -H 'Content-Type: application/json' -d '{"enabled": true}'
```

Claude Code ke liye:

```bash
claude mcp add --transport http freellmapi http://localhost:3001/mcp \
  --header "Authorization: Bearer freellmapi-YOUR-KEY"
```

> Claude Desktop (web/desktop chat) MCP tools use kar sakta hai, lekin woh aapki
> gateway ki "model" nahi ban jata — Claude hi jawab deta hai, gateway tools call hote hain.

---

## 8. Free provider keys (recommended)

| Provider | Free tier | Link |
|---|---|---|
| Groq | fast, generous | console.groq.com |
| Cerebras | fast, generous | cloud.cerebras.ai |
| Google AI Studio | Gemini free | aistudio.google.com |
| OpenRouter `:free` models | many models | openrouter.ai |
| Mistral | free tier | console.mistral.ai |
| LLM7 | 100 req/hr | llm7.io |

Ek hi provider par depend mat raho — dono gateways fallback ke liye bane hain.

---

## 9. Troubleshooting (jo actually aaye)

| Error | Fix |
|---|---|
| `./server: line 69: : command not found` | Node.js install nahi hai ya PATH mein nahi. `node -v` check karo; Termux: `pkg install nodejs-lts git openssl` |
| `better-sqlite3` "NODE_MODULE_VERSION 115 vs 127" | `npm rebuild better-sqlite3` (new Node se), ya wahi Node version use karo jisse install kiya |
| `libdl.so: cannot open shared object file` (Termux/Android) | glibc toolchain wale Node se rebuild karo: `CC=gcc CXX=g++ npm rebuild better-sqlite3 --build-from-source` |
| OmniRoute `e.util.markAsUncloneable is not a function` | Node 22.22.2+ / 24 LTS use karo (purane patch builds mein API missing hoti hai) |
| OmniRoute `EADDRINUSE :20128` | purana process band karo: `pkill -f "omniroute[.]mjs"` |
| OmniRoute login: "No password configured" | `INITIAL_PASSWORD=... omniroute` se start karo |
| OmniRoute `/v1/models` empty | koi provider connection nahi — Providers page se add karo |
| FreeLLMAPI `no_key` / 0 models | Keys page se provider key add karo (OVH/Kilo/AI Horde keyless hain) |
| `auto` → "No credentials for provider: openrouter" | explicit model do: `pol/openai`, `groq/...`, ya combo banao |
| Claude Code still hits old gateway | `~/.claude/settings.json` ka `env` shell ko override karta hai — file edit karo |
| `401 Invalid API key` | unified key (freellmapi) / `sk-` key (OmniRoute) use karo, dashboard token nahi |
| `--dangerously-skip-permissions` root par fail | `--permission-mode acceptEdits` use karo (root par Anthropic block karta hai) |

---

## 10. Notes / warnings

- Ye gateways **aapke apne provider accounts** use karte hain. Free tier limits provider ke
  hain, gateway ke nahi.
- Kuch "free" providers ke terms third-party clients allow nahi karte. Projects khud
  `tos: avoid` list rakhte hain — unhe auto-routing se hata rakha hai. Apni zimmedari par
  use karo.
- Public VPS par deploy kar rahe ho to: `REQUIRE_API_KEY=true`, strong `INITIAL_PASSWORD`,
  HTTPS reverse proxy, aur dashboard ko internet par expose mat karo.
- Gateway ko `0.0.0.0` par bind karne se pehle firewall laga lo.

---

## 11. Files in this folder

```
claude-gateway-setup/
├── server                         ← ONE command for both gateways
├── README.md                      ← ye guide
├── ANDROID.md                     ← Android/Termux + "9B tokens" ki asliyat
├── TEST-REPORT.md                 ← tested commands + outputs
├── docker-compose.yml             ← dono gateways Docker mein
├── .env.example
├── scripts/
│   ├── read-freellmapi-key.mjs    ← unified key DB se padhta hai
│   ├── setup-freellmapi.sh        ← manual install (Docker ke bagair)
│   ├── setup-omniroute.sh         ← manual install
│   ├── connect-claude.sh          ← settings.json safely likhta hai
│   ├── connect-claude-freellmapi.sh
│   ├── connect-claude-omniroute.sh
│   ├── test-gateway.mjs           ← models + OpenAI wire + Anthropic wire
│   ├── test-all.sh
│   └── stop-all.sh
└── configs/
    ├── settings.freellmapi.json
    ├── settings.omniroute.json
    └── claude_desktop_config.json
```
