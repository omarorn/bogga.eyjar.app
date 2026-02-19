# Load Tests

**Grafana k6 load testing scripts for Litla Gámaleigan backend**

## Quick Start

```bash
# Install k6
brew install k6  # macOS
# OR
sudo apt-get install k6  # Linux
# OR
choco install k6  # Windows

# Run all load tests
npm run load-test

# Run individual tests
npm run load-test:api          # API endpoints
npm run load-test:websocket    # WebSocket connections
npm run load-test:database     # Database queries
npm run load-test:iot          # IoT data ingestion

# Quick test (2 minutes, 50 users)
npm run load-test:quick

# Stress test (10 minutes, 500 users)
npm run load-test:stress
```

## Test Scripts

### 1. api-endpoints.js

Tests all 22 REST API endpoints with realistic user traffic patterns.

**Load Pattern:**
- Ramp up: 10 → 50 → 100 → 200 users over 7 minutes
- Sustain: 200 users for 2 minutes
- Ramp down: 100 → 0 users over 3 minutes
- **Total duration:** 13 minutes

**Endpoints Tested:**
- Dashboard stats
- Container CRUD (list, get, update)
- Customer listings
- Order management
- Alert system
- Sensor history queries

**Thresholds:**
- 95% of requests < 500ms
- 99% of requests < 1000ms
- Error rate < 5%

### 2. websocket-connections.js

Tests Durable Object hibernation under concurrent WebSocket connections.

**Load Pattern:**
- Ramp up: 100 → 500 → 1000 connections over 12 minutes
- Sustain: 1000 connections for 5 minutes (hibernation test)
- Ramp down: 500 → 0 connections over 5 minutes
- **Total duration:** 17 minutes

**What It Tests:**
- Concurrent WebSocket connections
- Message latency
- Hibernation API behavior
- Connection stability
- Durable Object scaling

**Thresholds:**
- 95% message latency < 200ms
- 99% message latency < 500ms
- Error rate < 5%

### 3. database-queries.js

Tests D1 database performance under concurrent read/write operations.

**Load Pattern:**
- Ramp up: 50 → 200 → 500 users over 9 minutes
- Sustain: 500 users for 5 minutes (peak query load)
- Ramp down: 100 → 0 users over 3 minutes
- **Total duration:** 12 minutes

**Query Mix:**
- 50% - Simple SELECT (container listings)
- 20% - JOIN queries (dashboard stats)
- 15% - Sensor history (complex queries)
- 10% - UPDATE operations
- 5% - INSERT operations

**Thresholds:**
- 95% reads < 300ms
- 95% writes < 500ms
- 95% JOINs < 1000ms
- Error rate < 5%

### 4. iot-ingestion.js

Simulates 50-200 IoT containers sending sensor data.

**Load Pattern:**
- Ramp up: 50 → 100 → 200 devices over 20 minutes
- Sustain: 200 devices for 10 minutes (peak ingestion)
- Ramp down: 100 → 0 devices over 10 minutes
- **Total duration:** 35 minutes

**What It Simulates:**
- Sensor data POST every 30 seconds (configurable)
- Photo uploads (10% of readings)
- Realistic sensor values (fill level, temperature, humidity, etc.)

**Thresholds:**
- 95% ingestion < 1000ms
- 99% ingestion < 2000ms
- Error rate < 1%

## Results

Results are saved to `load-test-results/` directory:

```
load-test-results/
├── api-endpoints-summary.json
├── websocket-summary.json
├── database-summary.json
├── iot-ingestion-summary.json
└── archives/
    └── 2026-01-03/
        ├── api-endpoints-summary.json
        └── ...
```

## Documentation

- **Full Guide:** [docs/LOAD_TESTING_GUIDE.md](../../docs/LOAD_TESTING_GUIDE.md)
- **Results Report:** [docs/LOAD_TEST_RESULTS.md](../../docs/LOAD_TEST_RESULTS.md)

## Environment Variables

Create `.env.loadtest` in project root:

```bash
API_URL=https://litla.workers.dev
WS_URL=wss://litla.workers.dev
IOT_INTERVAL=30  # Seconds between sensor readings
```

## Test User Setup

Load tests require authentication. Create a test user:

```bash
# Create test user in database
npx wrangler d1 execute litla-gamaleigan-db --remote --command \
  "INSERT INTO users (email, password, role, status) VALUES ('loadtest@example.com', 'hashed_password', 'admin', 'active')"
```

Update test credentials in `api-endpoints.js` and `database-queries.js`:

```javascript
const TEST_USER = {
  email: 'loadtest@example.com',
  password: 'YourTestPassword123!',
};
```

## Monitoring

During load tests, monitor:

1. **Cloudflare Dashboard:** Workers analytics (requests, errors, latency)
2. **k6 Output:** Real-time metrics in terminal
3. **Worker Logs:** `npx wrangler tail` in separate terminal

## Common Issues

### k6 Not Found

```bash
# Install k6
brew install k6  # macOS
```

### Authentication Failures

```bash
# Verify test user exists
npx wrangler d1 execute litla-gamaleigan-db --remote --command "SELECT * FROM users WHERE email = 'loadtest@example.com'"
```

### Rate Limiting Triggered

Expected behavior! Rate limiting is working correctly. To test higher loads, temporarily increase limits in `packages/workers/src/middleware/rateLimiter.ts`.

## Next Steps

1. Install k6
2. Create test user
3. Run baseline test: `npm run load-test:api`
4. Review results in `load-test-results/`
5. Document findings in `docs/LOAD_TEST_RESULTS.md`
6. Identify bottlenecks
7. Implement optimizations
8. Re-test to validate improvements

---

**Created:** January 3, 2026
**Status:** Ready for execution
