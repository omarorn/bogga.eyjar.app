/**
 * k6 Load Test: WebSocket Connections
 *
 * Tests Durable Object hibernation under concurrent WebSocket connections
 *
 * Usage:
 *   k6 run scripts/load-tests/websocket-connections.js
 *   k6 run --vus 500 --duration 10m scripts/load-tests/websocket-connections.js
 */

import ws from 'k6/ws';
import { check, sleep } from 'k6';
import { Counter, Rate, Trend } from 'k6/metrics';

// Custom metrics
const wsConnections = new Counter('websocket_connections');
const wsMessages = new Counter('websocket_messages');
const wsErrors = new Rate('websocket_errors');
const wsLatency = new Trend('websocket_latency');
const connectionDuration = new Trend('connection_duration');

// Configuration
const WS_URL = __ENV.WS_URL || 'wss://ws.gamaleigan.is';

// Load test stages: ramp up WebSocket connections
export const options = {
  stages: [
    { duration: '2m', target: 100 },   // Ramp to 100 connections
    { duration: '5m', target: 500 },   // Ramp to 500 connections
    { duration: '5m', target: 1000 },  // Peak: 1000 connections (test hibernation)
    { duration: '3m', target: 500 },   // Scale down
    { duration: '2m', target: 0 },     // Disconnect all
  ],
  thresholds: {
    'websocket_errors': ['rate<0.05'],           // Error rate < 5%
    'websocket_latency': ['p(95)<200', 'p(99)<500'], // 95% < 200ms
  },
};

/**
 * Main test: Connect to WebSocket and listen for updates
 */
export default function() {
  // Use different container IDs to distribute load across Durable Objects
  const containerId = Math.floor(Math.random() * 50) + 1100; // IDs 1100-1150
  const url = `${WS_URL}/gamur/${containerId}`;

  const startTime = Date.now();

  const res = ws.connect(url, {}, function(socket) {
    wsConnections.add(1);

    socket.on('open', () => {
      console.log(`✅ Connected to container ${containerId}`);
    });

    socket.on('message', (data) => {
      wsMessages.add(1);
      const latency = Date.now() - startTime;
      wsLatency.add(latency);

      try {
        const message = JSON.parse(data);
        check(message, {
          'message has fill_level': (msg) => msg.fill_level !== undefined,
          'message has temperature': (msg) => msg.temperature !== undefined,
        }) || wsErrors.add(1);
      } catch (e) {
        console.error('Failed to parse message:', e);
        wsErrors.add(1);
      }
    });

    socket.on('error', (e) => {
      console.error(`❌ WebSocket error for container ${containerId}:`, e);
      wsErrors.add(1);
    });

    socket.on('close', () => {
      const duration = Date.now() - startTime;
      connectionDuration.add(duration);
      console.log(`🔌 Disconnected from container ${containerId} (duration: ${duration}ms)`);
    });

    // Keep connection open for random duration (simulate real users)
    const connectionTime = Math.random() * 60 + 30; // 30-90 seconds
    socket.setTimeout(() => {
      console.log(`⏱️ Closing connection to container ${containerId} after ${connectionTime.toFixed(0)}s`);
      socket.close();
    }, connectionTime * 1000);
  });

  check(res, { 'websocket status 101': (r) => r && r.status === 101 });

  // Wait before next connection attempt
  sleep(5);
}

/**
 * Handle summary: Custom summary output
 */
export function handleSummary(data) {
  const summary = {
    totalConnections: wsConnections.value,
    totalMessages: wsMessages.value,
    errorRate: wsErrors.rate || 0,
    avgLatency: wsLatency.avg || 0,
    p95Latency: data.metrics.websocket_latency?.values['p(95)'] || 0,
    avgConnectionDuration: connectionDuration.avg || 0,
  };

  console.log('\n📊 WebSocket Load Test Summary:');
  console.log('═'.repeat(60));
  console.log(`Total Connections: ${summary.totalConnections}`);
  console.log(`Total Messages: ${summary.totalMessages}`);
  console.log(`Error Rate: ${(summary.errorRate * 100).toFixed(2)}%`);
  console.log(`Average Latency: ${summary.avgLatency.toFixed(2)}ms`);
  console.log(`P95 Latency: ${summary.p95Latency}ms`);
  console.log(`Avg Connection Duration: ${(summary.avgConnectionDuration / 1000).toFixed(2)}s`);
  console.log('═'.repeat(60));

  return {
    'load-test-results/websocket-summary.json': JSON.stringify(summary, null, 2),
  };
}
