import { describe, it, expect } from 'vitest';
import worker, { __test } from '../../src/index.js';

function b64urlJson(value) {
  return Buffer.from(JSON.stringify(value)).toString('base64url');
}

async function signJwt(payload, secret) {
  const header = b64urlJson({ alg: 'HS256', typ: 'JWT' });
  const body = b64urlJson(payload);
  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign']
  );
  const sig = await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(`${header}.${body}`));
  const sigB64 = Buffer.from(sig).toString('base64url');
  return `${header}.${body}.${sigB64}`;
}

class MockStatement {
  constructor(sql, db) {
    this.sql = sql;
    this.db = db;
    this.args = [];
  }

  bind(...args) {
    this.args = args;
    return this;
  }

  async first() {
    if (this.sql.includes('SELECT t.*, r.rule AS recurrence FROM tasks t JOIN lists l')) {
      return this.db.task;
    }
    return null;
  }

  async run() {
    this.db.runs.push({ sql: this.sql, args: this.args });
    return { success: true };
  }

  async all() {
    return { results: [] };
  }
}

function makeEnv(task = null) {
  const db = {
    task,
    runs: [],
    prepare(sql) {
      return new MockStatement(sql, this);
    },
  };

  return {
    DB: db,
    JWT_SECRET: 'test-secret',
    APP_NAME: 'Bogga',
    ASSETS: {
      async fetch() {
        return new Response('not-found', { status: 404 });
      },
    },
  };
}

async function patchTask(body, task = { id: 't1', list_id: 'l1', status: 'open', title: 'Old', tag: null, deadline: null, recurrence: null }) {
  const env = makeEnv(task);
  const token = await signJwt(
    { sub: 'u1', exp: Math.floor(Date.now() / 1000) + 60 * 60 },
    env.JWT_SECRET
  );
  const req = new Request('https://example.com/api/tasks/t1', {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify(body),
  });
  const res = await worker.fetch(req, env);
  const data = await res.json();
  return { res, data, env };
}

describe('task patch validation', () => {
  it('rejects unsupported status values', async () => {
    const { res, data } = await patchTask({ status: 'deleted' });
    expect(res.status).toBe(400);
    expect(data.error).toBe('Ógild staða');
  });

  it('rejects empty title after trim', async () => {
    const { res, data } = await patchTask({ title: '   ' });
    expect(res.status).toBe(400);
    expect(data.error).toBe('Titill vantar');
  });

  it('rejects invalid deadline format', async () => {
    const { res, data } = await patchTask({ deadline: '2026/02/19' });
    expect(res.status).toBe(400);
    expect(data.error).toBe('Ógildur frestur');
  });

  it('accepts valid payload and trims title/tag', async () => {
    const { res, data, env } = await patchTask({
      title: '  Nýr titill  ',
      tag: '  Heimili ',
      deadline: '2026-03-01',
      status: 'done',
    });

    expect(res.status).toBe(200);
    expect(data.ok).toBe(true);

    const update = env.DB.runs.find((r) => r.sql.startsWith('UPDATE tasks SET'));
    expect(update).toBeTruthy();
    expect(update.args).toContain('Nýr titill');
    expect(update.args).toContain('Heimili');
    expect(update.args).toContain('2026-03-01');
    expect(update.args).toContain('done');
  });
});

describe('date helpers', () => {
  it('normalizes valid deadlines and rejects invalid values', () => {
    expect(__test.normalizeDeadline('2026-02-19')).toBe('2026-02-19');
    expect(__test.normalizeDeadline('')).toBeNull();
    expect(__test.normalizeDeadline('2026/02/19')).toBeNull();
    expect(__test.normalizeDeadline('19-02-2026')).toBeNull();
  });

  it('computes monthly recurrence over month boundaries', () => {
    const next = __test.nextRecurringDeadline('2026-01-31', 'monthly');
    expect(next).toBeTypeOf('string');
    expect(next).toMatch(/^\d{4}-\d{2}-\d{2}$/);
  });
});
