---
paths: "src/**", "worker/**"
---

# Naming Conventions: Backend ↔ Frontend

**Purpose:** Consistent naming across the stack with clear boundary mapping.

## Convention

| Layer | Style | Example |
|-------|-------|---------|
| **Database (D1)** | snake_case | `created_at`, `user_id`, `job_title` |
| **Backend API (Workers)** | snake_case | `{ job_title: "...", created_at: "..." }` |
| **API Response** | snake_case | JSON uses snake_case |
| **Frontend (React)** | camelCase | `jobTitle`, `createdAt`, `userId` |
| **CSS classes** | kebab-case | `job-card`, `nav-button` |
| **Components** | PascalCase | `JobCard`, `NavButton` |
| **Files** | kebab-case | `job-card.tsx`, `nav-button.tsx` |

## Boundary Mapping

Use a field mapper at the API boundary:

```typescript
// utils/fieldMapper.ts
export function snakeToCamel(obj: Record<string, any>): Record<string, any> {
  return Object.fromEntries(
    Object.entries(obj).map(([key, value]) => [
      key.replace(/_([a-z])/g, (_, c) => c.toUpperCase()),
      value
    ])
  );
}

export function camelToSnake(obj: Record<string, any>): Record<string, any> {
  return Object.fromEntries(
    Object.entries(obj).map(([key, value]) => [
      key.replace(/[A-Z]/g, c => `_${c.toLowerCase()}`),
      value
    ])
  );
}
```

## API Client Pattern

```typescript
// Convert on fetch
async function fetchJobs(): Promise<Job[]> {
  const res = await fetch('/api/jobs');
  const { data } = await res.json();
  return data.map(snakeToCamel);
}

// Convert on submit
async function createJob(job: Job): Promise<void> {
  await fetch('/api/jobs', {
    method: 'POST',
    body: JSON.stringify(camelToSnake(job))
  });
}
```
