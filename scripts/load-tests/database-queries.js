/**
 * k6 Load Test: Database Query Performance
 *
 * Tests D1 database under concurrent read/write load
 *
 * Usage:
 *   k6 run scripts/load-tests/database-queries.js
 *   k6 run --vus 100 --duration 10m scripts/load-tests/database-queries.js
 */

import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend, Counter } from 'k6/metrics';

// Custom metrics
const readLatency = new Trend('db_read_latency');
const writeLatency = new Trend('db_write_latency');
const joinLatency = new Trend('db_join_latency');
const dbErrors = new Rate('db_errors');
const readOps = new Counter('db_reads');
const writeOps = new Counter('db_writes');

// Configuration
const BASE_URL = __ENV.API_URL || 'https://api.gamaleigan.is';

// Load test stages: high read load, lower write load
export const options = {
  stages: [
    { duration: '1m', target: 50 },    // Warm up
    { duration: '3m', target: 200 },   // High read load
    { duration: '5m', target: 500 },   // Peak read load (1000 req/s)
    { duration: '2m', target: 100 },   // Scale down
    { duration: '1m', target: 0 },     // Cool down
  ],
  thresholds: {
    'db_read_latency': ['p(95)<300', 'p(99)<500'],  // 95% reads < 300ms
    'db_write_latency': ['p(95)<500', 'p(99)<1000'], // 95% writes < 500ms
    'db_join_latency': ['p(95)<1000', 'p(99)<2000'], // 95% joins < 1s
    'db_errors': ['rate<0.05'],                       // Error rate < 5%
  },
};

/**
 * Setup: Authenticate
 */
export function setup() {
  const loginRes = http.post(`${BASE_URL}/api/auth/login`, JSON.stringify({
    email: 'loadtest@example.com',
    password: 'LoadTest123!',
  }), {
    headers: { 'Content-Type': 'application/json' },
  });

  if (loginRes.status === 200) {
    return { token: loginRes.json('token') };
  }
  return { token: null };
}

/**
 * Main test: Mix of read-heavy and write operations
 */
export default function(data) {
  const token = data.token;
  if (!token) return;

  const headers = {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${token}`,
  };

  // Weighted scenarios: 80% reads, 20% writes (realistic production ratio)
  const scenario = Math.random();

  if (scenario < 0.50) {
    // Scenario 1: Simple SELECT (50% of traffic)
    const startTime = Date.now();
    const res = http.get(`${BASE_URL}/api/gamar?limit=20`, { headers });
    readLatency.add(Date.now() - startTime);
    readOps.add(1);

    check(res, {
      'simple select success': (r) => r.status === 200,
    }) || dbErrors.add(1);

  } else if (scenario < 0.70) {
    // Scenario 2: JOIN query (20% of traffic) - dashboard stats
    const startTime = Date.now();
    const res = http.get(`${BASE_URL}/api/dashboard/stats`, { headers });
    joinLatency.add(Date.now() - startTime);
    readOps.add(1);

    check(res, {
      'join query success': (r) => r.status === 200,
      'join query has data': (r) => r.json('totalContainers') !== undefined,
    }) || dbErrors.add(1);

  } else if (scenario < 0.85) {
    // Scenario 3: Sensor history (15% of traffic) - complex query
    const containerId = Math.floor(Math.random() * 50) + 1100;
    const startTime = Date.now();
    const res = http.get(`${BASE_URL}/api/gamar/${containerId}/saga?limit=100`, { headers });
    joinLatency.add(Date.now() - startTime);
    readOps.add(1);

    check(res, {
      'sensor history success': (r) => r.status === 200,
    }) || dbErrors.add(1);

  } else if (scenario < 0.95) {
    // Scenario 4: UPDATE operation (10% of traffic)
    const containerId = Math.floor(Math.random() * 50) + 1100;
    const startTime = Date.now();
    const res = http.put(`${BASE_URL}/api/gamar/${containerId}`, JSON.stringify({
      location: `Test Location ${Math.floor(Math.random() * 1000)}`,
      status: 'active',
    }), { headers });
    writeLatency.add(Date.now() - startTime);
    writeOps.add(1);

    check(res, {
      'update success': (r) => r.status === 200,
    }) || dbErrors.add(1);

  } else {
    // Scenario 5: INSERT operation (5% of traffic) - create alert
    const startTime = Date.now();
    const res = http.post(`${BASE_URL}/api/alerts`, JSON.stringify({
      containerId: Math.floor(Math.random() * 50) + 1100,
      type: 'manual',
      severity: 'low',
      message: `Load test alert ${Date.now()}`,
    }), { headers });
    writeLatency.add(Date.now() - startTime);
    writeOps.add(1);

    check(res, {
      'insert success': (r) => r.status === 201 || r.status === 200,
    }) || dbErrors.add(1);
  }

  // Random think time
  sleep(Math.random() * 2 + 0.5); // 0.5-2.5 seconds
}

/**
 * Handle summary
 */
export function handleSummary(data) {
  const summary = {
    totalReads: readOps.value,
    totalWrites: writeOps.value,
    readWriteRatio: (readOps.value / writeOps.value).toFixed(2),
    avgReadLatency: readLatency.avg || 0,
    avgWriteLatency: writeLatency.avg || 0,
    avgJoinLatency: joinLatency.avg || 0,
    p95ReadLatency: data.metrics.db_read_latency?.values['p(95)'] || 0,
    p95WriteLatency: data.metrics.db_write_latency?.values['p(95)'] || 0,
    p95JoinLatency: data.metrics.db_join_latency?.values['p(95)'] || 0,
    errorRate: dbErrors.rate || 0,
  };

  console.log('\n📊 Database Load Test Summary:');
  console.log('═'.repeat(60));
  console.log(`Total Reads: ${summary.totalReads}`);
  console.log(`Total Writes: ${summary.totalWrites}`);
  console.log(`Read/Write Ratio: ${summary.readWriteRatio}:1`);
  console.log('');
  console.log('Average Latency:');
  console.log(`  Simple SELECT: ${summary.avgReadLatency.toFixed(2)}ms`);
  console.log(`  JOIN queries: ${summary.avgJoinLatency.toFixed(2)}ms`);
  console.log(`  Write operations: ${summary.avgWriteLatency.toFixed(2)}ms`);
  console.log('');
  console.log('P95 Latency:');
  console.log(`  Simple SELECT: ${summary.p95ReadLatency}ms`);
  console.log(`  JOIN queries: ${summary.p95JoinLatency}ms`);
  console.log(`  Write operations: ${summary.p95WriteLatency}ms`);
  console.log('');
  console.log(`Error Rate: ${(summary.errorRate * 100).toFixed(2)}%`);
  console.log('═'.repeat(60));

  return {
    'load-test-results/database-summary.json': JSON.stringify(summary, null, 2),
  };
}
