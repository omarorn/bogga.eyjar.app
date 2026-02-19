---
paths: "migrations/**", "src/routes/**"
---

# Database Insert Order (FK Constraints)

**Purpose:** Ensure correct insertion order to satisfy foreign key constraints.

## Phase Ordering

```
Phase 1: Base Tables (no FK dependencies)
  → people, locations, categories, tags

Phase 2: Main Entities (depend on Phase 1)
  → stories, jobs, appointments, records

Phase 3: Relationships (depend on Phase 1 + 2)
  → story_people, job_comments, relationships

Phase 4: Analysis/Metadata (depend on all above)
  → ai_insights, patterns, analytics
```

## Batch Insert Pattern

```typescript
// Always insert in FK order
const statements = [
  // Phase 1
  env.DB.prepare('INSERT INTO people (name) VALUES (?)').bind(name),
  // Phase 2
  env.DB.prepare('INSERT INTO stories (title, author_id) VALUES (?, ?)').bind(title, authorId),
  // Phase 3
  env.DB.prepare('INSERT INTO story_people (story_id, person_id) VALUES (?, ?)').bind(storyId, personId),
];

const results = await env.DB.batch(statements);
```

## Delete Order (Reverse!)

```
Phase 4 → Phase 3 → Phase 2 → Phase 1
```

Delete child records before parent records to avoid FK violations.

## Critical Notes
- Always verify parent records exist before inserting children
- Use `ON DELETE CASCADE` for automatic cleanup where appropriate
- Run D1 migrations to remote BEFORE deploying new code
