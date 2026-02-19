# Database Operation Pattern Template

**Purpose:** Standardize database operations for Cloudflare D1 with proper error handling and transaction support
**Applies to:** Files matching `**/db/**/*.ts`, `**/repositories/**/*.ts`
**Priority:** P1 (Critical)
**Created:** January 2025
**Author:** 2076 ehf

---

## Rule: All Database Operations Must Follow Standard Patterns

### Connection & Environment

```typescript
// types/env.ts
export interface Env {
  DB: D1Database;
  // Other bindings...
}

// Always access via env.DB, never create new connections
```

---

## Query Patterns

### SELECT - Single Record

```typescript
// ✅ GOOD: Type-safe single record query
interface User {
  id: string;
  name: string;
  email: string;
  created_at: string;
}

async function getUserById(env: Env, id: string): Promise<User | null> {
  const result = await env.DB.prepare(
    'SELECT id, name, email, created_at FROM users WHERE id = ?'
  ).bind(id).first<User>();
  
  return result;
}

// ❌ BAD: Using .all() for single record
async function getUserById(env: Env, id: string) {
  const result = await env.DB.prepare(
    'SELECT * FROM users WHERE id = ?'
  ).bind(id).all();
  return result.results[0]; // Wasteful
}
```

### SELECT - Multiple Records

```typescript
// ✅ GOOD: Paginated list query
interface ListResult<T> {
  items: T[];
  total: number;
  hasMore: boolean;
}

async function listUsers(
  env: Env,
  page: number = 1,
  limit: number = 20
): Promise<ListResult<User>> {
  const offset = (page - 1) * limit;
  
  // Get total count
  const countResult = await env.DB.prepare(
    'SELECT COUNT(*) as count FROM users'
  ).first<{ count: number }>();
  const total = countResult?.count || 0;
  
  // Get paginated results
  const result = await env.DB.prepare(
    'SELECT id, name, email, created_at FROM users ORDER BY created_at DESC LIMIT ? OFFSET ?'
  ).bind(limit, offset).all<User>();
  
  return {
    items: result.results,
    total,
    hasMore: offset + limit < total
  };
}
```

### INSERT

```typescript
// ✅ GOOD: Insert with generated ID
async function createUser(
  env: Env,
  data: { name: string; email: string }
): Promise<User> {
  const id = crypto.randomUUID();
  const now = new Date().toISOString();
  
  await env.DB.prepare(
    'INSERT INTO users (id, name, email, created_at) VALUES (?, ?, ?, ?)'
  ).bind(id, data.name, data.email, now).run();
  
  // Return the created record
  const created = await env.DB.prepare(
    'SELECT * FROM users WHERE id = ?'
  ).bind(id).first<User>();
  
  if (!created) {
    throw new Error('Failed to create user');
  }
  
  return created;
}
```

### UPDATE

```typescript
// ✅ GOOD: Update with optimistic locking
async function updateUser(
  env: Env,
  id: string,
  data: Partial<{ name: string; email: string }>
): Promise<User | null> {
  // Check exists first
  const existing = await env.DB.prepare(
    'SELECT * FROM users WHERE id = ?'
  ).bind(id).first<User>();
  
  if (!existing) {
    return null;
  }
  
  const now = new Date().toISOString();
  
  await env.DB.prepare(`
    UPDATE users 
    SET name = COALESCE(?, name),
        email = COALESCE(?, email),
        updated_at = ?
    WHERE id = ?
  `).bind(data.name, data.email, now, id).run();
  
  return await env.DB.prepare(
    'SELECT * FROM users WHERE id = ?'
  ).bind(id).first<User>();
}
```

### DELETE

```typescript
// ✅ GOOD: Soft delete pattern
async function deleteUser(env: Env, id: string): Promise<boolean> {
  const result = await env.DB.prepare(
    'UPDATE users SET deleted_at = ? WHERE id = ? AND deleted_at IS NULL'
  ).bind(new Date().toISOString(), id).run();
  
  return result.meta.changes > 0;
}

// Alternative: Hard delete
async function hardDeleteUser(env: Env, id: string): Promise<boolean> {
  const result = await env.DB.prepare(
    'DELETE FROM users WHERE id = ?'
  ).bind(id).run();
  
  return result.meta.changes > 0;
}
```

---

## Batch Operations

### Batch Insert

```typescript
// ✅ GOOD: Batch insert with transaction
async function createUsers(
  env: Env,
  users: Array<{ name: string; email: string }>
): Promise<User[]> {
  const now = new Date().toISOString();
  const statements: D1PreparedStatement[] = [];
  const ids: string[] = [];
  
  for (const user of users) {
    const id = crypto.randomUUID();
    ids.push(id);
    
    statements.push(
      env.DB.prepare(
        'INSERT INTO users (id, name, email, created_at) VALUES (?, ?, ?, ?)'
      ).bind(id, user.name, user.email, now)
    );
  }
  
  // Execute as batch (transactional)
  await env.DB.batch(statements);
  
  // Fetch created records
  const placeholders = ids.map(() => '?').join(',');
  const result = await env.DB.prepare(
    `SELECT * FROM users WHERE id IN (${placeholders})`
  ).bind(...ids).all<User>();
  
  return result.results;
}
```

---

## Foreign Key Constraint Order

### Insert Order (Parent → Child)

```typescript
// ✅ GOOD: Respect foreign key order
async function createStoryWithRelations(env: Env, data: StoryInput) {
  const statements: D1PreparedStatement[] = [];
  
  // Phase 1: Base tables (no FK dependencies)
  const personId = crypto.randomUUID();
  statements.push(
    env.DB.prepare('INSERT INTO people (id, name) VALUES (?, ?)')
      .bind(personId, data.personName)
  );
  
  // Phase 2: Main entity
  const storyId = crypto.randomUUID();
  statements.push(
    env.DB.prepare('INSERT INTO stories (id, title, content) VALUES (?, ?, ?)')
      .bind(storyId, data.title, data.content)
  );
  
  // Phase 3: Relations (depends on Phase 1 & 2)
  statements.push(
    env.DB.prepare('INSERT INTO relationships (story_id, person_id) VALUES (?, ?)')
      .bind(storyId, personId)
  );
  
  await env.DB.batch(statements);
}
```

### Delete Order (Child → Parent)

```typescript
// ✅ GOOD: Delete in reverse order
async function deleteStoryWithRelations(env: Env, storyId: string) {
  const statements: D1PreparedStatement[] = [];
  
  // Phase 1: Delete children first
  statements.push(
    env.DB.prepare('DELETE FROM relationships WHERE story_id = ?').bind(storyId)
  );
  statements.push(
    env.DB.prepare('DELETE FROM ai_insights WHERE story_id = ?').bind(storyId)
  );
  
  // Phase 2: Delete main entity
  statements.push(
    env.DB.prepare('DELETE FROM stories WHERE id = ?').bind(storyId)
  );
  
  await env.DB.batch(statements);
}
```

---

## JSON Field Handling

### Storing JSON

```typescript
// ✅ GOOD: JSON serialization
async function createStoryWithMetadata(
  env: Env,
  data: {
    title: string;
    content: string;
    metadata: Record<string, unknown>;
    tags: string[];
  }
): Promise<void> {
  await env.DB.prepare(`
    INSERT INTO stories (id, title, content, metadata, tags)
    VALUES (?, ?, ?, json(?), json(?))
  `).bind(
    crypto.randomUUID(),
    data.title,
    data.content,
    JSON.stringify(data.metadata),
    JSON.stringify(data.tags)
  ).run();
}
```

### Reading JSON

```typescript
// ✅ GOOD: JSON parsing with fallback
interface StoryWithMetadata {
  id: string;
  title: string;
  metadata: string; // Stored as JSON string in D1
  tags: string;
}

async function getStoryWithParsedJSON(env: Env, id: string) {
  const result = await env.DB.prepare(
    'SELECT * FROM stories WHERE id = ?'
  ).bind(id).first<StoryWithMetadata>();
  
  if (!result) return null;
  
  return {
    ...result,
    metadata: JSON.parse(result.metadata || '{}'),
    tags: JSON.parse(result.tags || '[]')
  };
}
```

---

## Error Handling

```typescript
// ✅ GOOD: Comprehensive error handling
async function safeCreateUser(
  env: Env,
  data: { name: string; email: string }
): Promise<{ success: boolean; data?: User; error?: string }> {
  try {
    // Check for duplicate email
    const existing = await env.DB.prepare(
      'SELECT id FROM users WHERE email = ?'
    ).bind(data.email).first();
    
    if (existing) {
      return { success: false, error: 'Email already exists' };
    }
    
    const user = await createUser(env, data);
    return { success: true, data: user };
    
  } catch (error) {
    console.error('Database error:', error);
    
    if (error instanceof Error) {
      // Check for constraint violations
      if (error.message.includes('UNIQUE constraint failed')) {
        return { success: false, error: 'Duplicate entry' };
      }
      if (error.message.includes('FOREIGN KEY constraint failed')) {
        return { success: false, error: 'Referenced record not found' };
      }
    }
    
    return { success: false, error: 'Database operation failed' };
  }
}
```

---

## Verification Checklist

- [ ] Use `.first<T>()` for single records, `.all<T>()` for lists
- [ ] Always `.bind()` parameters (never string concatenation)
- [ ] Include `created_at` and `updated_at` timestamps
- [ ] Respect foreign key order in batch operations
- [ ] Handle JSON fields with `json()` function
- [ ] Implement proper error handling
- [ ] Return created/updated records after mutations

---

## References

- **Cloudflare D1 Docs:** https://developers.cloudflare.com/d1/
- **D1 SQL Reference:** https://developers.cloudflare.com/d1/reference/sql/

---

**This template ensures safe, efficient database operations in Cloudflare D1.**
