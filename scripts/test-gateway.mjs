#!/usr/bin/env node
// Gateway smoke test — models + OpenAI wire + Anthropic wire.
// Usage: node test-gateway.mjs <baseUrl> <apiKey> [model]
//   node test-gateway.mjs http://localhost:3001 freellmapi-xxx auto
//   node test-gateway.mjs http://localhost:20128 sk-xxx pol/openai

const [, , baseArg, key, modelArg] = process.argv;
if (!baseArg || !key) {
  console.error('Usage: node test-gateway.mjs <baseUrl> <apiKey> [model]');
  process.exit(2);
}
const base = baseArg.replace(/\/+$/, '').replace(/\/v1$/, '');
const model = modelArg || 'auto';
const timeoutMs = Number(process.env.TEST_TIMEOUT_MS || 90_000);

const result = { gateway: base, model, checks: [] };
const check = (name, ok, detail) => {
  result.checks.push({ name, ok, detail });
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${detail ? ' — ' + detail : ''}`);
};

async function req(path, { method = 'GET', headers = {}, body } = {}) {
  const ctrl = new AbortController();
  const t = setTimeout(() => ctrl.abort(), timeoutMs);
  try {
    const res = await fetch(base + path, {
      method,
      headers: { 'Content-Type': 'application/json', ...headers },
      body: body ? JSON.stringify(body) : undefined,
      signal: ctrl.signal,
    });
    const text = await res.text();
    return { status: res.status, text };
  } finally {
    clearTimeout(t);
  }
}

// 1) models
try {
  const r = await req('/v1/models', { headers: { Authorization: `Bearer ${key}` } });
  let count = null;
  try {
    const j = JSON.parse(r.text);
    count = Array.isArray(j.data) ? j.data.length : null;
  } catch {}
  check('GET /v1/models', r.status === 200 && (count === null || count > 0),
    `HTTP ${r.status}${count !== null ? `, ${count} models` : ''}`);
} catch (e) {
  check('GET /v1/models', false, e.message);
}

// 2) OpenAI wire
try {
  const r = await req('/v1/chat/completions', {
    method: 'POST',
    headers: { Authorization: `Bearer ${key}` },
    body: {
      model,
      stream: false,
      messages: [{ role: 'user', content: 'Reply with exactly: OPENAI_WIRE_OK' }],
      max_tokens: 32,
    },
  });
  let txt = r.text;
  try {
    const j = JSON.parse(txt);
    txt = j.choices?.[0]?.message?.content ?? j.error?.message ?? JSON.stringify(j).slice(0, 200);
  } catch {}
  check('POST /v1/chat/completions', r.status === 200, `HTTP ${r.status} — ${String(txt).slice(0, 140)}`);
} catch (e) {
  check('POST /v1/chat/completions', false, e.message);
}

// 3) Anthropic wire (jo Claude Code use karta hai)
try {
  const r = await req('/v1/messages', {
    method: 'POST',
    headers: { 'x-api-key': key, 'anthropic-version': '2023-06-01' },
    body: { model, max_tokens: 64, messages: [{ role: 'user', content: 'Reply with exactly: CLAUDE_WIRE_OK' }] },
  });
  let out = r.text;
  let parsed = null;
  try { parsed = JSON.parse(out); } catch {}
  if (parsed?.content) {
    out = parsed.content.map((c) => c.text ?? c.thinking ?? '').join(' ').trim();
  } else if (parsed?.error) {
    out = parsed.error.message ?? JSON.stringify(parsed.error);
  } else {
    const textDeltas = out
      .split('\n')
      .filter((l) => l.startsWith('data: '))
      .map((l) => {
        try { return JSON.parse(l.slice(6)); } catch { return null; }
      })
      .filter(Boolean)
      .filter((e) => e.type === 'content_block_delta')
      .map((e) => e.delta?.text ?? '')
      .join('');
    out = textDeltas || out.replace(/<[^>]+>/g, ' ').slice(0, 160);
  }
  check('POST /v1/messages (Anthropic)', r.status === 200, `HTTP ${r.status} — ${String(out).slice(0, 160)}`);
} catch (e) {
  check('POST /v1/messages (Anthropic)', false, e.message);
}

const failed = result.checks.filter((c) => !c.ok).length;
console.log(failed === 0 ? '\nALL CHECKS PASSED' : `\n${failed} CHECK(S) FAILED`);
process.exit(failed === 0 ? 0 : 1);
