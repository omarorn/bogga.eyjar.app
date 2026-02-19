---
paths: "**/durable-objects/*.ts", "packages/workers/src/durable-objects/*.ts"
---

# Durable Objects Business Logic Separation

Durable Objects should orchestrate state and WebSocket connections, not implement complex business logic. Extract business logic to service modules.

## Pattern

| If Claude suggests... | Use instead... |
|----------------------|----------------|
| Implementing 50+ line methods in Durable Objects | Extract to `services/` modules, call from DO |
| Complex database queries in DO methods | Extract to service functions that accept `env` |
| Alert/notification logic in DO | Extract to `services/alerts/` or `services/notifications/` |
| Statistics calculation in DO | Extract to `services/stats/` or similar |

## Service Function Signature Pattern

Extracted service functions should follow this pattern:

```typescript
export async function processBusinessLogic(
  env: Env,                    // Worker environment (DB, R2, etc.)
  identifier: string,           // Entity ID or key
  data: DataType,              // Context needed for processing
  callback?: (msg: any) => void // Optional callback (e.g., broadcast)
): Promise<Result> {
  // Business logic here
  return result;
}
```

## Implementation Example

**Before (business logic in DO):**
```typescript
class ContainerObject extends DurableObject {
  async checkAlerts() {
    // 80 lines of alert detection logic
    // 90 lines of notification sending
    // 20 lines of database operations
  }
}
```

**After (extracted to service):**
```typescript
// services/alerts/containerAlerts.ts
export async function processContainerAlerts(
  env: Env,
  containerId: string,
  currentData: ContainerData,
  broadcastCallback?: (message: any) => void
): Promise<number> {
  // All alert logic here
  return alertCount;
}

// durable-objects/ContainerObject.ts
class ContainerObject extends DurableObject {
  async checkAlerts() {
    this.state.alertCount = await processContainerAlerts(
      this.env,
      this.containerId,
      this.state.currentData,
      this.broadcast.bind(this)
    );
  }
}
```

## Benefits

- **Testability**: Service functions can be unit tested independently
- **Reusability**: Logic can be used outside Durable Objects
- **Clarity**: DO methods stay focused on orchestration
- **Maintainability**: Business logic changes don't touch DO structure

## Extraction Targets

Extract when you see:
- DO methods >50 lines
- Complex database query logic
- Business rule processing
- External API calls
- Alert/notification logic
- Statistics calculations
- Data transformation logic

## Keep in Durable Objects

- WebSocket lifecycle (fetch, webSocketMessage, webSocketClose, webSocketError)
- State management (reading/writing to this.ctx.storage)
- Connection tracking (this.connections Set)
- Alarm scheduling
- Simple orchestration (<20 lines calling services)

## Directory Structure

```
packages/workers/src/
├── durable-objects/
│   ├── ContainerObject.ts    # Orchestration only
│   └── DashboardObject.ts    # Orchestration only
└── services/
    ├── alerts/
    │   └── containerAlerts.ts # Alert business logic
    └── dashboardStats.ts      # Statistics business logic
```

## Context

Discovered during refactoring where ContainerObject.ts had 174 lines of alert logic (31% of file) and DashboardObject.ts had 132 lines of statistics logic (27% of file). Extraction reduced DO files by 22-30% and created reusable service modules.
