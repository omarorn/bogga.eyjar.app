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
        COUNT(t.id) AS total_count
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
    const token = crypto.randomUUID().replace(/-/g, '').substring(0, 16);
    await env.DB.prepare('UPDATE lists SET share_token = ? WHERE id = ? AND owner_id = ?')
      .bind(token, seg[1], p.sub).run();
    return json({ token });
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
      'SELECT * FROM tasks WHERE list_id = ? ORDER BY CASE WHEN deadline IS NULL THEN 1 ELSE 0 END, deadline ASC, created_at DESC'
    ).bind(seg[1]).all();
    return json({ list, tasks: results });
  }

  if (seg[0] === 'lists' && seg[2] === 'tasks' && method === 'POST') {
    const p = await auth(request, env);
    if (!p) return err('Unauthorized', 401);
    const list = await env.DB.prepare('SELECT id FROM lists WHERE id = ? AND owner_id = ?').bind(seg[1], p.sub).first();
    if (!list) return err('Fannst ekki', 404);
    const { title, deadline, tag } = await request.json().catch(() => ({}));
    if (!title?.trim()) return err('Titill vantar');
    const id = crypto.randomUUID();
    await env.DB.prepare('INSERT INTO tasks (id, list_id, title, deadline, tag) VALUES (?, ?, ?, ?, ?)')
      .bind(id, seg[1], title.trim(), deadline || null, tag?.trim() || null).run();
    return json({ id, title: title.trim(), deadline: deadline || null, tag: tag?.trim() || null, status: 'open' }, 201);
  }

  if (seg[0] === 'tasks' && seg.length === 2 && method === 'PATCH') {
    const p = await auth(request, env);
    if (!p) return err('Unauthorized', 401);
    const task = await env.DB.prepare(
      'SELECT t.* FROM tasks t JOIN lists l ON l.id = t.list_id WHERE t.id = ? AND l.owner_id = ?'
    ).bind(seg[1], p.sub).first();
    if (!task) return err('Fannst ekki', 404);
    const updates = await request.json().catch(() => ({}));
    const fields = [], values = [];
    if (updates.status !== undefined) { fields.push('status = ?'); values.push(updates.status); }
    if (updates.title !== undefined) { fields.push('title = ?'); values.push(updates.title); }
    if (updates.deadline !== undefined) { fields.push('deadline = ?'); values.push(updates.deadline || null); }
    if (updates.tag !== undefined) { fields.push('tag = ?'); values.push(updates.tag || null); }
    if (!fields.length) return err('Ekkert að uppfæra');
    await env.DB.prepare(`UPDATE tasks SET ${fields.join(', ')} WHERE id = ?`).bind(...values, seg[1]).run();
    return json({ ok: true });
  }

  if (seg[0] === 'tasks' && seg.length === 2 && method === 'DELETE') {
    const p = await auth(request, env);
    if (!p) return err('Unauthorized', 401);
    await env.DB.prepare(
      'DELETE FROM tasks WHERE id = ? AND list_id IN (SELECT id FROM lists WHERE owner_id = ?)'
    ).bind(seg[1], p.sub).run();
    return json({ ok: true });
  }

  if (seg[0] === 'share' && seg.length === 2 && method === 'GET') {
    const list = await env.DB.prepare('SELECT id, title, color FROM lists WHERE share_token = ?').bind(seg[1]).first();
    if (!list) return err('Fannst ekki', 404);
    const { results } = await env.DB.prepare(
      'SELECT * FROM tasks WHERE list_id = ? ORDER BY CASE WHEN deadline IS NULL THEN 1 ELSE 0 END, deadline ASC, created_at DESC'
    ).bind(list.id).all();
    return json({ list, tasks: results });
  }

  if (seg[0] === 'share' && seg[2] === 'tasks' && method === 'POST') {
    const list = await env.DB.prepare('SELECT id FROM lists WHERE share_token = ?').bind(seg[1]).first();
    if (!list) return err('Fannst ekki', 404);
    const { title, deadline, tag } = await request.json().catch(() => ({}));
    if (!title?.trim()) return err('Titill vantar');
    const id = crypto.randomUUID();
    await env.DB.prepare('INSERT INTO tasks (id, list_id, title, deadline, tag) VALUES (?, ?, ?, ?, ?)')
      .bind(id, list.id, title.trim(), deadline || null, tag?.trim() || null).run();
    return json({ id, title: title.trim(), deadline: deadline || null, tag: tag?.trim() || null, status: 'open' }, 201);
  }

  return err('Fannst ekki', 404);
}
