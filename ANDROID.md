# Android par setup + "9 Billion tokens" ki asliyat

> Ye doc documentation + testing notes par based hai. Android device par maine khud
> test nahi kiya (sandbox Linux hai), lekin commands dono projects ke official
> Android/Termux guides se hain.

---

## 1. Short answer

| Sawal | Jawab |
|---|---|
| Android par chal sakta hai? | ✅ Haan — dono (Termux), FreeLLMAPI ka official Android app bhi hai |
| Claude Code phone par? | ⚠️ Termux mein possible, official support nahi; proot-distro zyada reliable |
| 9B tokens Claude mein use ho sakte hain? | ❌ Nahi — ye Claude tokens nahi hain |
| 9B tokens kahin use ho sakte hain? | ✅ Haan — Claude Code / Cline / OpenCode / Aider / chat apps mein, **apne provider accounts** ke through |

---

## 2. Android setup — FreeLLMAPI

### Option A: Official Android app (sab se aasan)

Play Store par **FreeLLMAPI** app hai (`co.freellmapi.app`). App se apna
gateway/account connect karo. Phone par Node/Termux ki zaroorat nahi.

### Option B: Termux (phone hi server ban jata hai)

Requirements: Android 7+, ~1 GB free, **Termux F-Droid se** (Play Store wala purana hai),
Node 22.13+ (24 LTS best).

```bash
pkg update && pkg upgrade -y
pkg install -y nodejs-lts git

git clone https://github.com/tashfeenahmed/freellmapi.git
cd freellmapi
npm install --no-audit --no-fund
npm run dev
```

- Dashboard: `http://localhost:5173`
- API: `http://localhost:3001/v1`

Android par FreeLLMAPI native `better-sqlite3` ki jagah Node ka built-in `node:sqlite`
use karta hai — is liye "better-sqlite3 install warning" ignore kar sakte ho.

**Screen off hone par process na mare:**

```bash
pkg install -y termux-api
termux-wake-lock
# band karna ho to:
termux-wake-unlock
```

Settings mein Termux ki **battery optimization disable** karo.

**Laptop se phone ka gateway use karna (same Wi-Fi):**

```bash
HOST=0.0.0.0 npm run dev:lan
ip addr show wlan0        # phone ka IP
```

Laptop par: `http://PHONE_IP:5173` (dashboard), `http://PHONE_IP:3001/v1` (API).
Internet par direct expose mat karo — Tailscale/private VPN use karo.

---

## 3. Android setup — OmniRoute

```bash
pkg install nodejs
INITIAL_PASSWORD='StrongPass123!' npx -y omniroute --no-open
```

- Dashboard: `http://localhost:20128`
- API: `http://localhost:20128/v1`

Pehli boot par `INITIAL_PASSWORD` zaroor do, warna login "No password configured" dega.

**PWA:** dashboard browser mein kholo → "Add to Home Screen" → fullscreen app jaisa.

**24/7 chalane ke liye:** `termux-wake-lock` + battery optimization off. Phone ko
charger par rakho; continuously chalane se heat/battery wear hota hai — purana phone
ya Raspberry Pi better hai.

**Node version:** OmniRoute ko Node **22.22.2+ / 24 LTS** chahiye. Termux ka
`nodejs-lts` usually 24.x hota hai; `node -v` se check karo.

---

## 4. Claude Code phone par

Claude Code ek Node CLI hai. Termux par chal sakta hai, lekin Anthropic officially
Android support nahi karta. Do raste:

### A) Seedha Termux

```bash
pkg install -y nodejs-lts ripgrep
npm i -g @anthropic-ai/claude-code
claude --version
```

Phir gateway se connect:

```bash
# FreeLLMAPI
npx freellmapi setup-claude --url http://localhost:3001 --api-key freellmapi-XXXX

# ya OmniRoute
omniroute setup-claude
```

### B) proot-distro Ubuntu (zyada reliable)

```bash
pkg install -y proot-distro
proot-distro install ubuntu
proot-distro login ubuntu

apt update && apt install -y nodejs npm git
npm i -g @anthropic-ai/claude-code
claude --version
```

Ubuntu ke andar `localhost` phone ka hi localhost hai, is liye `http://localhost:3001`
kaam karega (agar gateway Termux mein chal raha hai).

### C) Sab se practical: gateway phone par, Claude Code laptop par

Phone par gateway chalao (`HOST=0.0.0.0`), laptop se LAN IP use karo:

```json
// laptop ke ~/.claude/settings.json
{
  "env": {
    "ANTHROPIC_BASE_URL": "http://PHONE_IP:3001",
    "ANTHROPIC_AUTH_TOKEN": "freellmapi-XXXX",
    "ANTHROPIC_MODEL": "auto"
  }
}
```

Ye fastest aur sab se stable hai — phone sirf server ka kaam karta hai.

---

## 5. "9 Billion tokens" — asliyat

Numbers jo aap ne dekhe:

| Project | Claim |
|---|---|
| FreeLLMAPI | ~7.4B tokens / month |
| OmniRoute | ~1.62B tokens / month |
| **Total** | **~9B tokens / month** |

Ye number **kisi ke paas jama hua balance nahi** hai. Ye dono projects ke apne
README mein likha hua **estimate** hai: "agar aap saare eligible third-party free
tiers sign up karke poora use karo".

### 4 wajahain kyun 9B literal nahi:

1. **Overlap / double counting.** Dono projects wahi providers count karte hain
   (Groq, Cerebras, Gemini, NVIDIA, Mistral...). Dono chalane se quota double nahi
   hota — same API key ka quota dono jagah **share** hota hai. 7.4 + 1.62 = 9.02
   sirf paper par hai.
2. **Aap ko khud signup karna hoga.** Har provider par apna account, API key,
   kabhi card/verification. Gateway khud tokens nahi deta.
3. **Monthly + per-minute limits.** Free tiers mahine/day/minute par capped hote hain.
   Ek saath 9B use nahi kar sakte; 1M-token requests par rate limit turant lagti hai.
4. **Quality mix.** Bohat se "free tokens" chhote/weak models par hain. Coding ke liye
   sirf kuch models (Groq/Cerebras/Nemotron/Gemini Flash) practically useful hain.

**Realistic:** 5–10 providers ke keys se aap tens to hundreds of millions tokens/month
kar sakte ho — jo individual coding ke liye kaafi hai, par "9B" marketing ceiling hai,
guaranteed capacity nahi.

---

## 6. Kya ye Claude tokens hain? ❌

Nahi. Ye **third-party providers** ke free tiers hain (Groq, Cerebras, Google, NVIDIA,
Mistral, Pollinations, etc.). Anthropic **Claude models ka free API tier nahi** deta.

| Chahiye | Kya karna hoga |
|---|---|
| Claude Opus/Sonnet models | Anthropic API key (paid) **ya** Claude Pro/Max subscription |
| Free/cheap coding models | Ye gateways + Groq/Cerebras/Gemini keys ✅ |
| Claude Code ka interface, non-Claude model | Ye gateways ✅ (Claude Code sirf client hai) |
| claude.ai website mein gateway | ❌ possible nahi |

Claude Code gateway ke saath chalane ka matlab ye **nahi** ke aap Claude model use kar
rahe ho — aap Claude Code ka UI/tools use kar rahe ho, model provider ka hota hai
(response mein `model` field dekho).

Kuch aggregators (OpenRouter, Kilo, AgentRouter) paid credits par Claude models dete
hain, lekin wo free nahi.

---

## 7. Kahan use kar sakte ho (9B wali capacity)

Claude Code ke ilawa — koi bhi OpenAI-compatible ya Anthropic-compatible client:

**Coding:** Claude Code, Cline, Roo Code, Kilo Code, OpenCode, Aider, Continue,
Codex CLI, Goose, Crush, Qwen Code, OpenClaw, Cursor (custom base URL).

**Chat/apps:** LibreChat, Open WebUI, Jan, Chatbox, SillyTavern, LobeChat,
Open Interpreter, n8n / LangChain / LlamaIndex (OpenAI SDK `base_url`).

Base URL:
- OpenAI wire → `http://localhost:3001/v1` ya `http://localhost:20128/v1`
- Anthropic wire → root URL (`:3001` / `:20128`), Claude Code khud `/v1/messages` lagata hai

---

## 8. Android par practical recommendation

1. **Sirf ek gateway** chalao phone par — dono chalane ka faida kam, RAM/battery zyada.
2. FreeLLMAPI Termux par (Node 24) — SQLite built-in, setup simple.
3. 3–5 real free keys daalo (Groq, Cerebras, Gemini, OpenRouter free, Mistral) —
   keyless providers sirf test ke liye.
4. Claude Code laptop par chalao, phone ko LAN server banao (sab se stable).
5. Phone ko 24/7 charger par + `termux-wake-lock` + battery optimization off.
6. Public internet par expose **mat** karo; Tailscale use karo.
7. Ek hi provider par multiple accounts banana — ToS violation + ban risk. Mat karo.

---

## 9. Quick reference

```bash
# FreeLLMAPI (Termux)
pkg install -y nodejs-lts git
git clone https://github.com/tashfeenahmed/freellmapi.git && cd freellmapi
npm install --no-audit --no-fund && npm run dev
# dashboard :5173 | api :3001

# OmniRoute (Termux)
pkg install nodejs
INITIAL_PASSWORD='StrongPass123!' npx -y omniroute --no-open
# dashboard + api :20128

# wake lock
pkg install -y termux-api && termux-wake-lock

# LAN access (FreeLLMAPI)
HOST=0.0.0.0 npm run dev:lan
```
