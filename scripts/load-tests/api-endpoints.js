/**
 * k6 Load Test: API Endpoints
 *
 * Tests all 22 REST API endpoints with realistic traffic patterns
 *
 * Usage:
 *   k6 run scripts/load-tests/api-endpoints.js
 *   k6 run --vus 100 --duration 5m scripts/load-tests/api-endpoints.js
 *   k6 run --stage 1m:10,5m:100,1m:0 scripts/load-tests/api-endpoints.js
 */

import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend, Counter } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');
const authLatency = new Trend('auth_latency');
const containerLatency = new Trend('container_latency');
const orderLatency = new Trend('order_latency');
const apiCalls = new Counter('api_calls');

// Configuration
const BASE_URL = __ENV.API_URL || 'https://api.gamaleigan.is';

// Load test stages: ramp up gradually to avoid overwhelming Workers
export const options = {
  stages: [
    { duration: '1m', target: 10 },   // Warm up: 10 users
    { duration: '2m', target: 50 },   // Ramp up: 50 users
    { duration: '5m', target: 100 },  // Plateau: 100 users
    { duration: '2m', target: 200 },  // Peak load: 200 users
    { duration: '2m', target: 100 },  // Scale down: 100 users
    { duration: '1m', target: 0 },    // Cool down: 0 users
  ],
  thresholds: {
    'http_req_duration': ['p(95)<500', 'p(99)<1000'], // 95% < 500ms, 99% < 1s
    'http_req_failed': ['rate<0.05'],                  // Error rate < 5%
    'errors': ['rate<0.05'],
  },
};

// Test credentials (use test account, not production admin)
const TEST_USER = {
  email: 'loadtest@example.com',
  password: 'LoadTest123!',
};

// Global state
let authToken = null;

/**
 * Setup: Runs once before load test starts
 * Creates test user and authenticates
 */
export function setup() {
  console.log(`🚀 Starting load test against ${BASE_URL}`);

  // Authenticate and get JWT token
  const loginRes = http.post(`${BASE_URL}/api/auth/login`, JSON.stringify({
    email: TEST_USER.email,
    password: TEST_USER.password,
  }), {
    headers: { 'Content-Type': 'application/json' },
  });

  if (loginRes.status === 200) {
    const token = loginRes.json('token');
    console.log('✅ Authentication successful');
    return { token };
  } else {
    console.error('❌ Authentication failed:', loginRes.status);
    return { token: null };
  }
}

/**
 * Main test scenario: Simulates realistic user behavior
 */
export default function(data) {
  const token = data.token;
  if (!token) {
    console.error('No auth token available, skipping test');
    return;
  }

  const headers = {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${token}`,
  };

  // Scenario 1: View dashboard (common operation)
  let res = http.get(`${BASE_URL}/api/dashboard/stats`, { headers });
  apiCalls.add(1);
  check(res, {
    'dashboard stats 200': (r) => r.status === 200,
  }) || errorRate.add(1);
  sleep(1);

  // Scenario 2: List containers (high frequency)
  res = http.get(`${BASE_URL}/api/gamar?limit=20&offset=0`, { headers });
  apiCalls.add(1);
  containerLatency.add(res.timings.duration);
  check(res, {
    'containers list 200': (r) => r.status === 200,
    'containers list has data': (r) => r.json('containers') !== undefined,
  }) || errorRate.add(1);
  sleep(2);

  // Scenario 3: Get single container (medium frequency)
  const containerId = 1189; // Use existing container ID
  res = http.get(`${BASE_URL}/api/gamar/${containerId}`, { headers });
  apiCalls.add(1);
  containerLatency.add(res.timings.duration);
  check(res, {
    'container get 200': (r) => r.status === 200,
  }) || errorRate.add(1);
  sleep(1);

  // Scenario 4: List customers (medium frequency)
  res = http.get(`${BASE_URL}/api/vidskiptavinir?limit=20`, { headers });
  apiCalls.add(1);
  check(res, {
    'customers list 200': (r) => r.status === 200,
  }) || errorRate.add(1);
  sleep(2);

  // Scenario 5: List orders (medium frequency)
  res = http.get(`${BASE_URL}/api/pantanir?limit=20`, { headers });
  apiCalls.add(1);
  orderLatency.add(res.timings.duration);
  check(res, {
    'orders list 200': (r) => r.status === 200,
  }) || errorRate.add(1);
  sleep(1);

  // Scenario 6: List alerts (medium frequency)
  res = http.get(`${BASE_URL}/api/alerts?limit=10`, { headers });
  apiCalls.add(1);
  check(res, {
    'alerts list 200': (r) => r.status === 200,
  }) || errorRate.add(1);
  sleep(3);

  // Scenario 7: Get sensor history (low frequency, expensive query)
  res = http.get(`${BASE_URL}/api/gamar/${containerId}/saga?limit=50`, { headers });
  apiCalls.add(1);
  check(res, {
    'sensor history 200': (r) => r.status === 200,
  }) || errorRate.add(1);
  sleep(5);

  // Random think time: simulate user reading/interacting
  sleep(Math.random() * 5 + 2); // 2-7 seconds
}

/**
 * Teardown: Runs once after load test completes
 */
export function teardown(data) {
  console.log('🏁 Load test complete');
  console.log(`   Total API calls: ${apiCalls.value}`);
}

/**
 * Handle summary: Custom summary output
 */
export function handleSummary(data) {
  return {
    'stdout': textSummary(data, { indent: '  ', enableColors: true }),
    'load-test-results/api-endpoints-summary.json': JSON.stringify(data),
  };
}

function textSummary(data, options) {
  const { indent = '', enableColors = false } = options;

  const lines = [
    '',
    '📊 Load Test Summary: API Endpoints',
    '═'.repeat(60),
    '',
    `Total Requests: ${data.metrics.http_reqs.values.count}`,
    `Failed Requests: ${data.metrics.http_req_failed.values.passes} (${(data.metrics.http_req_failed.values.rate * 100).toFixed(2)}%)`,
    '',
    'Response Times:',
    `  p50: ${data.metrics.http_req_duration.values['p(50)']}ms`,
    `  p95: ${data.metrics.http_req_duration.values['p(95)']}ms`,
    `  p99: ${data.metrics.http_req_duration.values['p(99)']}ms`,
    '',
    'Custom Metrics:',
    `  Auth Latency (avg): ${data.metrics.auth_latency?.values.avg || 'N/A'}ms`,
    `  Container Latency (avg): ${data.metrics.container_latency?.values.avg || 'N/A'}ms`,
    `  Order Latency (avg): ${data.metrics.order_latency?.values.avg || 'N/A'}ms`,
    '',
    '═'.repeat(60),
    '',
  ];

  return lines.join('\n');
}
