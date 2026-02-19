---
paths: "**/*"
---

# Todo List Tracking for Phase Work

When starting a new phase or major task, immediately create a TodoWrite list to track progress.

## Pattern

```typescript
TodoWrite([
  {
    content: "First task description",
    status: "in_progress",
    activeForm: "Doing first task"
  },
  {
    content: "Second task description",
    status: "pending",
    activeForm: "Doing second task"
  },
  {
    content: "Third task description",
    status: "pending",
    activeForm: "Doing third task"
  }
])
```

## Guidelines

- **Break work into 3-5 concrete tasks** (not too granular)
- **Mark first task as "in_progress"**, rest as "pending"
- **Use action verbs** in content ("Execute script", "Update file", "Test feature")
- **activeForm uses present continuous** ("Executing script", "Updating file")
- **Update immediately** when completing tasks (don't batch)

## When to Create Todo List

✅ **Do create:**
- Starting a new implementation phase
- Beginning multi-step task (>3 steps)
- Working through task list from tasks.md
- Agent delegation (track agent tasks)

❌ **Don't create:**
- Single-step operations
- Quick file reads/searches
- Exploratory work (no defined outcome)

## Why

- System reminds if TodoWrite not used (enforces good practice)
- Provides visibility into progress
- Helps prevent forgetting tasks
- Enables better status updates to user
