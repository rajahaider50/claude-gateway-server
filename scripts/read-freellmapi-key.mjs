#!/usr/bin/env node
// Read FreeLLMAPI's unified API key from its SQLite database.
// Usage: node read-freellmapi-key.mjs <freellmapi-dir> <db-path>
// Works with better-sqlite3 (desktop) and node:sqlite (Android/Termux).

import { createRequire } from 'node:module';
import path from 'node:path';
import fs from 'node:fs';

const [, , dir, dbPath] = process.argv;
if (!dir || !dbPath) {
  console.error('Usage: node read-freellmapi-key.mjs <freellmapi-dir> <db-path>');
  process.exit(2);
}
if (!fs.existsSync(dbPath)) process.exit(1);

const SQL = "SELECT value FROM settings WHERE key = 'unified_api_key'";

function viaBetterSqlite3() {
  const require = createRequire(path.join(dir, 'package.json'));
  const Database = require('better-sqlite3');
  const db = new Database(dbPath, { readonly: true });
  try {
    return db.prepare(SQL).get()?.value ?? null;
  } finally {
    db.close();
  }
}

async function viaNodeSqlite() {
  const { DatabaseSync } = await import('node:sqlite');
  const db = new DatabaseSync(dbPath, { readOnly: true });
  try {
    return db.prepare(SQL).get()?.value ?? null;
  } finally {
    db.close();
  }
}

try {
  let key = null;
  try {
    key = viaBetterSqlite3();
  } catch {
    key = await viaNodeSqlite();
  }
  if (!key) process.exit(1);
  process.stdout.write(String(key) + '\n');
} catch (err) {
  console.error(err.message);
  process.exit(1);
}
