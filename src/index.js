// ============================================================
// bogga-app Worker — API + SPA serving
// ============================================================

// ── Crypto utils ────────────────────────────────────────────

async function hashPIN(pin) {
  const buf = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(pin));
  return Array.from(new Uint8Array(buf)).map(b => b.toString(16).padStart(2, '0')).join('');
}

async function signJWT(payload, secret) {
  const enc = (v) => btoa(JSON.stringify(v)).replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');
  const header = enc({ alg: 'HS256', typ: 'JWT' });
  const body = enc(payload);
  const key = await crypto.subtle.importKey(
    'raw', new TextEncoder().encode(secret),
    { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']
  );
  const sig = await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(`${header}.${body}`));
  const sigB64 = btoa(String.fromCharCode(...new Uint8Array(sig)))
    .replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');
  return `${header}.${body}.${sigB64}`;
}

async function verifyJWT(token, secret) {
  try {
    const parts = token.split('.');
    if (parts.length !== 3) return null;
    const [header, body, sig] = parts;
    const key = await crypto.subtle.importKey(
      'raw', new TextEncoder().encode(secret),
      { name: 'HMAC', hash: 'SHA-256' }, false, ['verify']
    );
    const sigPadded = sig.replace(/-/g, '+').replace(/_/g, '/') + '=='.slice(0, (4 - sig.length % 4) % 4);
    const sigBuf = Uint8Array.from(atob(sigPadded), c => c.charCodeAt(0));
    const valid = await crypto.subtle.verify('HMAC', key, sigBuf, new TextEncoder().encode(`${header}.${body}`));
    if (!valid) return null;
    const bodyPadded = body.replace(/-/g, '+').replace(/_/g, '/') + '=='.slice(0, (4 - body.length % 4) % 4);
    const payload = JSON.parse(atob(bodyPadded));
    if (payload.exp && payload.exp < Math.floor(Date.now() / 1000)) return null;
    return payload;
  } catch {
    return null;
  }
}

// ── Response helpers ─────────────────────────────────────────

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET,POST,PATCH,DELETE,OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type,Authorization',
};

function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json', ...CORS },
  });
}

function err(msg, status = 400) {
  return json({ error: msg }, status);
}

// ── Auth ──────────────────────────────────────────────────────

async function auth(request, env) {
  const h = request.headers.get('Authorization');
  if (!h?.startsWith('Bearer ')) return null;
  return verifyJWT(h.slice(7), env.JWT_SECRET);
}

function normalizeRecurrence(rule) {
  if (rule === null || rule === undefined || rule === '') return null;
  const v = String(rule).trim().toLowerCase();
  return ['daily', 'weekly', 'monthly'].includes(v) ? v : null;
}

function nextRecurringDeadline(deadline, recurrence) {
  const base = deadline ? new Date(`${deadline}T00:00:00`) : new Date();
  if (Number.isNaN(base.getTime())) return null;
  if (recurrence === 'daily') base.setDate(base.getDate() + 1);
  if (recurrence === 'weekly') base.setDate(base.getDate() + 7);
  if (recurrence === 'monthly') base.setMonth(base.getMonth() + 1);
  return base.toISOString().slice(0, 10);
}

// ── Main export ───────────────────────────────────────────────

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const { pathname: path } = url;
    const method = request.method;

    if (method === 'OPTIONS') return new Response(null, { headers: CORS });

    if (path.startsWith('/api/')) {
      return handleAPI(path, method, request, env);
    }

    // SPA fallback — serve index.html for all non-asset routes
    try {
      const res = await env.ASSETS.fetch(request);
      if (res.status === 404) {
        return env.ASSETS.fetch(new Request(new URL('/index.html', request.url).toString()));
      }
      return res;
    } catch {
      return env.ASSETS.fetch(new Request(new URL('/index.html', request.url).toString()));
    }
  },
};

// ── API router ────────────────────────────────────────────────

async function handleAPI(path, method, request, env) {
  const seg = path.replace(/^\/api\//, '').split('/');
  const shareRoleFromToken = (token) => (token?.startsWith('v_') ? 'viewer' : 'editor');

  if (path === '/api/status' && method === 'GET') {
    const user = await env.DB.prepare('SELECT id FROM users LIMIT 1').first();
    return json({ setup: !!user });
  }

  if (path === '/api/auth/setup' && method === 'POST') {
    const existing = await env.DB.prepare('SELECT id FROM users LIMIT 1').first();
    if (existing) return err('Already set up', 403);
    const { pin, name } = await request.json().catch(() => ({}));
    if (!pin || !/^\d{4}$/.test(pin)) return err('PIN verður að vera 4 tölur');
    const id = crypto.randomUUID();
    const pin_hash = await hashPIN(pin);
    await env.DB.prepare('INSERT INTO users (id, pin_hash, display_name) VALUES (?, ?, ?)')
      .bind(id, pin_hash, name?.trim() || 'Bogga').run();
    const token = await signJWT({ sub: id, exp: Math.floor(Date.now() / 1000) + 86400 * 7 }, env.JWT_SECRET);
    return json({ token, name: name?.trim() || 'Bogga' }, 201);
  }

  if (path === '/api/auth/login' && method === 'POST') {
    const { pin } = await request.json().catch(() => ({}));
    if (!pin) return err('PIN vantar');
    const pin_hash = await hashPIN(pin);
    const user = await env.DB.prepare('SELECT * FROM users WHERE pin_hash = ? LIMIT 1').bind(pin_hash).first();
    if (!user) return err('Rangt PIN', 401);
    const token = await signJWT({ sub: user.id, exp: Math.floor(Date.now() / 1000) + 86400 * 7 }, env.JWT_SECRET);
    return json({ token, name: user.display_name });
  }

  if (path === '/api/lists' && method === 'GET') {
    const p = await auth(request, env);
    if (!p) return err('Unauthorized', 401);
    const { results } = await env.DB.prepare(`
      SELECT l.*,
        COUNT(CASE WHEN t.status = 'open' THEN 1 END) AS open_count,
        COUNT(CASE WHEN t.status != 'deleted' THEN 1 END) AS total_count
      FROM lists l
      LEFT JOIN tasks t ON t.list_id = l.id
      WHERE l.owner_id = ?
      GROUP BY l.id
      ORDER BY l.created_at DESC
    `).bind(p.sub).all();
    return json(results);
  }

  if (path === '/api/lists' && method === 'POST') {
    const p = await auth(request, env);
    if (!p) return err('Unauthorized', 401);
    const { title, color } = await request.json().catch(() => ({}));
    if (!title?.trim()) return err('Titill vantar');
    const id = crypto.randomUUID();
    await env.DB.prepare('INSERT INTO lists (id, owner_id, title, color) VALUES (?, ?, ?, ?)')
      .bind(id, p.sub, title.trim(), color || '#6366f1').run();
    return json({ id, title: title.trim(), color: color || '#6366f1', open_count: 0, total_count: 0 }, 201);
  }

  if (seg[0] === 'lists' && seg.length === 2 && method === 'DELETE') {
    const p = await auth(request, env);
    if (!p) return err('Unauthorized', 401);
    await env.DB.prepare('DELETE FROM lists WHERE id = ? AND owner_id = ?').bind(seg[1], p.sub).run();
    return json({ ok: true });
  }

  if (seg[0] === 'lists' && seg[2] === 'share' && method === 'POST') {
    const p = await auth(request, env);
    if (!p) return err('Unauthorized', 401);
    const { role } = await request.json().catch(() => ({}));
    const shareRole = role === 'viewer' ? 'viewer' : 'editor';
    const prefix = shareRole === 'viewer' ? 'v_' : 'e_';
    const token = `${prefix}${crypto.randomUUID().replace(/-/g, '').substring(0, 14)}`;
    await env.DB.prepare('UPDATE lists SET share_token = ? WHERE id = ? AND owner_id = ?')
      .bind(token, seg[1], p.sub).run();
    return json({ token, role: shareRole });
  }

  if (seg[0] === 'lists' && seg[2] === 'share' && method === 'DELETE') {
    const p = await auth(request, env);
    if (!p) return err('Unauthorized', 401);
    await env.DB.prepare('UPDATE lists SET share_token = NULL WHERE id = ? AND owner_id = ?')
      .bind(seg[1], p.sub).run();
    return json({ ok: true });
  }

  if (seg[0] === 'lists' && seg[2] === 'tasks' && method === 'GET') {
    const p = await auth(request, env);
    if (!p) return err('Unauthorized', 401);
    const list = await env.DB.prepare('SELECT * FROM lists WHERE id = ? AND owner_id = ?').bind(seg[1], p.sub).first();
    if (!list) return err('Fannst ekki', 404);
    const { results } = await env.DB.prepare(
      'SELECT t.*, r.rule AS recurrence FROM tasks t LEFT JOIN task_recurrence r ON r.task_id = t.id WHERE t.list_id = ? AND t.status != ? ORDER BY CASE WHEN t.deadline IS NULL THEN 1 ELSE 0 END, t.deadline ASC, t.created_at DESC'
    ).bind(seg[1], 'deleted').all();
    return json({ list, tasks: results });
  }

  if (seg[0] === 'lists' && seg[2] === 'trash' && method === 'GET') {
    const p = await auth(request, env);
    if (!p) return err('Unauthorized', 401);
    const list = await env.DB.prepare('SELECT id, title FROM lists WHERE id = ? AND owner_id = ?').bind(seg[1], p.sub).first();
    if (!list) return err('Fannst ekki', 404);
    const { results } = await env.DB.prepare(
      'SELECT t.*, r.rule AS recurrence FROM tasks t LEFT JOIN task_recurrence r ON r.task_id = t.id WHERE t.list_id = ? AND t.status = ? ORDER BY t.created_at DESC'
    ).bind(seg[1], 'deleted').all();
    return json({ list, tasks: results });
  }

  if (seg[0] === 'lists' && seg[2] === 'tasks' && method === 'POST') {
    const p = await auth(request, env);
    if (!p) return err('Unauthorized', 401);
    const list = await env.DB.prepare('SELECT id FROM lists WHERE id = ? AND owner_id = ?').bind(seg[1], p.sub).first();
    if (!list) return err('Fannst ekki', 404);
    const { title, deadline, tag, recurrence } = await request.json().catch(() => ({}));
    if (!title?.trim()) return err('Titill vantar');
    const id = crypto.randomUUID();
    const recurrenceRule = normalizeRecurrence(recurrence);
    await env.DB.prepare('INSERT INTO tasks (id, list_id, title, deadline, tag) VALUES (?, ?, ?, ?, ?)')
      .bind(id, seg[1], title.trim(), deadline || null, tag?.trim() || null).run();
    if (recurrenceRule) {
      await env.DB.prepare('INSERT OR REPLACE INTO task_recurrence (task_id, rule) VALUES (?, ?)')
        .bind(id, recurrenceRule).run();
    }
    return json({ id, title: title.trim(), deadline: deadline || null, tag: tag?.trim() || null, status: 'open', recurrence: recurrenceRule }, 201);
  }

  if (seg[0] === 'tasks' && seg.length === 2 && method === 'PATCH') {
    const p = await auth(request, env);
    if (!p) return err('Unauthorized', 401);
    const task = await env.DB.prepare(
      'SELECT t.*, r.rule AS recurrence FROM tasks t JOIN lists l ON l.id = t.list_id LEFT JOIN task_recurrence r ON r.task_id = t.id WHERE t.id = ? AND l.owner_id = ?'
    ).bind(seg[1], p.sub).first();
    if (!task) return err('Fannst ekki', 404);
    const updates = await request.json().catch(() => ({}));
    const fields = [], values = [];
    if (updates.status !== undefined) { fields.push('status = ?'); values.push(updates.status); }
    if (updates.title !== undefined) { fields.push('title = ?'); values.push(updates.title); }
    if (updates.deadline !== undefined) { fields.push('deadline = ?'); values.push(updates.deadline || null); }
    if (updates.tag !== undefined) { fields.push('tag = ?'); values.push(updates.tag || null); }
    const recurrenceInPayload = Object.prototype.hasOwnProperty.call(updates, 'recurrence');
    const recurrenceRule = recurrenceInPayload ? normalizeRecurrence(updates.recurrence) : task.recurrence;
    if (!fields.length && !recurrenceInPayload) return err('Ekkert að uppfæra');
    if (fields.length) {
      await env.DB.prepare(`UPDATE tasks SET ${fields.join(', ')} WHERE id = ?`).bind(...values, seg[1]).run();
    }
    if (recurrenceInPayload) {
      if (recurrenceRule) {
        await env.DB.prepare('INSERT OR REPLACE INTO task_recurrence (task_id, rule) VALUES (?, ?)')
          .bind(seg[1], recurrenceRule).run();
      } else {
        await env.DB.prepare('DELETE FROM task_recurrence WHERE task_id = ?').bind(seg[1]).run();
      }
    }
    if (updates.status === 'done' && task.status !== 'done' && recurrenceRule) {
      const nextDeadline = nextRecurringDeadline(updates.deadline !== undefined ? updates.deadline : task.deadline, recurrenceRule);
      const newTaskId = crypto.randomUUID();
      const newTitle = updates.title !== undefined ? updates.title : task.title;
      const newTag = updates.tag !== undefined ? updates.tag : task.tag;
      await env.DB.prepare('INSERT INTO tasks (id, list_id, title, deadline, tag, status) VALUES (?, ?, ?, ?, ?, ?)')
        .bind(newTaskId, task.list_id, newTitle, nextDeadline, newTag || null, 'open').run();
      await env.DB.prepare('INSERT OR REPLACE INTO task_recurrence (task_id, rule) VALUES (?, ?)')
        .bind(newTaskId, recurrenceRule).run();
    }
    return json({ ok: true });
  }

  if (seg[0] === 'tasks' && seg.length === 2 && method === 'DELETE') {
    const p = await auth(request, env);
    if (!p) return err('Unauthorized', 401);
    await env.DB.prepare(
      'UPDATE tasks SET status = ? WHERE id = ? AND list_id IN (SELECT id FROM lists WHERE owner_id = ?)'
    ).bind('deleted', seg[1], p.sub).run();
    return json({ ok: true });
  }

  if (seg[0] === 'tasks' && seg[2] === 'restore' && method === 'POST') {
    const p = await auth(request, env);
    if (!p) return err('Unauthorized', 401);
    await env.DB.prepare(
      'UPDATE tasks SET status = ? WHERE id = ? AND status = ? AND list_id IN (SELECT id FROM lists WHERE owner_id = ?)'
    ).bind('open', seg[1], 'deleted', p.sub).run();
    return json({ ok: true });
  }

  if (seg[0] === 'tasks' && seg[2] === 'purge' && method === 'DELETE') {
    const p = await auth(request, env);
    if (!p) return err('Unauthorized', 401);
    await env.DB.prepare(`
      DELETE FROM task_recurrence
      WHERE task_id = ?
        AND EXISTS (
          SELECT 1 FROM tasks t
          JOIN lists l ON l.id = t.list_id
          WHERE t.id = ? AND l.owner_id = ?
        )
    `).bind(seg[1], seg[1], p.sub).run();
    await env.DB.prepare(
      'DELETE FROM tasks WHERE id = ? AND status = ? AND list_id IN (SELECT id FROM lists WHERE owner_id = ?)'
    ).bind(seg[1], 'deleted', p.sub).run();
    return json({ ok: true });
  }

  if (seg[0] === 'share' && seg.length === 2 && method === 'GET') {
    const list = await env.DB.prepare('SELECT id, title, color FROM lists WHERE share_token = ?').bind(seg[1]).first();
    if (!list) return err('Fannst ekki', 404);
    const role = shareRoleFromToken(seg[1]);
    const { results } = await env.DB.prepare(
      'SELECT t.*, r.rule AS recurrence FROM tasks t LEFT JOIN task_recurrence r ON r.task_id = t.id WHERE t.list_id = ? AND t.status != ? ORDER BY CASE WHEN t.deadline IS NULL THEN 1 ELSE 0 END, t.deadline ASC, t.created_at DESC'
    ).bind(list.id, 'deleted').all();
    return json({ list, tasks: results, role });
  }

  if (seg[0] === 'share' && seg[2] === 'tasks' && method === 'POST') {
    if (shareRoleFromToken(seg[1]) === 'viewer') return err('Aðeins eigandi eða ritari mega bæta við', 403);
    const list = await env.DB.prepare('SELECT id FROM lists WHERE share_token = ?').bind(seg[1]).first();
    if (!list) return err('Fannst ekki', 404);
    const { title, deadline, tag, recurrence } = await request.json().catch(() => ({}));
    if (!title?.trim()) return err('Titill vantar');
    const id = crypto.randomUUID();
    const recurrenceRule = normalizeRecurrence(recurrence);
    await env.DB.prepare('INSERT INTO tasks (id, list_id, title, deadline, tag) VALUES (?, ?, ?, ?, ?)')
      .bind(id, list.id, title.trim(), deadline || null, tag?.trim() || null).run();
    if (recurrenceRule) {
      await env.DB.prepare('INSERT OR REPLACE INTO task_recurrence (task_id, rule) VALUES (?, ?)')
        .bind(id, recurrenceRule).run();
    }
    return json({ id, title: title.trim(), deadline: deadline || null, tag: tag?.trim() || null, status: 'open', recurrence: recurrenceRule }, 201);
  }

  return err('Fannst ekki', 404);
}
