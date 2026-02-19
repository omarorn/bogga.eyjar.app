/**
 * k6 Load Test: IoT Data Ingestion
 *
 * Simulates 50-200 containers sending sensor data every 5 minutes
 *
 * Usage:
 *   k6 run scripts/load-tests/iot-ingestion.js
 *   k6 run --vus 200 --duration 30m scripts/load-tests/iot-ingestion.js
 */

import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend, Counter } from 'k6/metrics';

// Custom metrics
const ingestionLatency = new Trend('iot_ingestion_latency');
const ingestionErrors = new Rate('iot_ingestion_errors');
const sensorReadings = new Counter('sensor_readings');
const photoUploads = new Counter('photo_uploads');

// Configuration
const BASE_URL = __ENV.API_URL || 'https://api.gamaleigan.is';

// Load test stages: simulate 50-200 IoT devices
export const options = {
  stages: [
    { duration: '5m', target: 50 },    // 50 devices (1 reading every 5 min)
    { duration: '10m', target: 100 },  // 100 devices
    { duration: '10m', target: 200 },  // 200 devices (peak load)
    { duration: '5m', target: 100 },   // Scale down
    { duration: '5m', target: 0 },     // All devices offline
  ],
  thresholds: {
    'iot_ingestion_latency': ['p(95)<1000', 'p(99)<2000'], // 95% < 1s
    'iot_ingestion_errors': ['rate<0.01'],                  // Error rate < 1%
  },
};

/**
 * Generate realistic sensor data
 */
function generateSensorData(containerId) {
  // Realistic ranges for waste container sensors
  return {
    containerId,
    fill_level: Math.floor(Math.random() * 100), // 0-100%
    temperature: (Math.random() * 30 + 5).toFixed(1), // 5-35°C
    humidity: (Math.random() * 40 + 40).toFixed(1), // 40-80%
    door_open: Math.random() > 0.9, // 10% chance door is open
    weight: (Math.random() * 500 + 50).toFixed(2), // 50-550 kg
    battery: (Math.random() * 40 + 60).toFixed(0), // 60-100%
    signal_strength: Math.floor(Math.random() * 40 - 90), // -90 to -50 dBm
    timestamp: new Date().toISOString(),
  };
}

/**
 * Main test: Send sensor data every 5 minutes
 */
export default function() {
  // Each VU represents one IoT device (container)
  const containerId = 1100 + __VU; // VU 1 = container 1101, etc.

  // Generate and send sensor reading
  const sensorData = generateSensorData(containerId);
  const startTime = Date.now();

  const res = http.post(`${BASE_URL}/api/innforsla/skynjari`, JSON.stringify(sensorData), {
    headers: { 'Content-Type': 'application/json' },
  });

  const latency = Date.now() - startTime;
  ingestionLatency.add(latency);
  sensorReadings.add(1);

  const success = check(res, {
    'sensor ingestion 200': (r) => r.status === 200,
    'sensor ingestion response time < 2s': (r) => r.timings.duration < 2000,
  });

  if (!success) {
    ingestionErrors.add(1);
    console.error(`❌ Sensor ingestion failed for container ${containerId}: ${res.status}`);
  }

  // 10% of readings include a photo upload (simulate camera capture)
  if (Math.random() < 0.1) {
    // Generate small dummy image data (simulate 100KB photo)
    const imageData = 'data:image/jpeg;base64,' + 'A'.repeat(1024 * 100);

    const photoRes = http.post(`${BASE_URL}/api/innforsla/mynd`, JSON.stringify({
      containerId,
      image: imageData,
      timestamp: new Date().toISOString(),
    }), {
      headers: { 'Content-Type': 'application/json' },
      timeout: '30s', // Photo uploads may take longer
    });

    if (photoRes.status === 200) {
      photoUploads.add(1);
    } else {
      ingestionErrors.add(1);
      console.error(`❌ Photo upload failed for container ${containerId}: ${photoRes.status}`);
    }
  }

  // Sleep for 5 minutes (300 seconds) - realistic IoT reporting interval
  // In load test, use shorter interval for faster results
  const sleepTime = __ENV.IOT_INTERVAL || 30; // Default: 30s (for testing)
  sleep(sleepTime);
}

/**
 * Handle summary
 */
export function handleSummary(data) {
  const summary = {
    totalSensorReadings: sensorReadings.value,
    totalPhotoUploads: photoUploads.value,
    avgIngestionLatency: ingestionLatency.avg || 0,
    p95IngestionLatency: data.metrics.iot_ingestion_latency?.values['p(95)'] || 0,
    p99IngestionLatency: data.metrics.iot_ingestion_latency?.values['p(99)'] || 0,
    errorRate: ingestionErrors.rate || 0,
    throughput: (sensorReadings.value / (data.state.testRunDurationMs / 1000)).toFixed(2),
  };

  console.log('\n📊 IoT Ingestion Load Test Summary:');
  console.log('═'.repeat(60));
  console.log(`Total Sensor Readings: ${summary.totalSensorReadings}`);
  console.log(`Total Photo Uploads: ${summary.totalPhotoUploads}`);
  console.log(`Throughput: ${summary.throughput} readings/sec`);
  console.log('');
  console.log('Ingestion Latency:');
  console.log(`  Average: ${summary.avgIngestionLatency.toFixed(2)}ms`);
  console.log(`  P95: ${summary.p95IngestionLatency}ms`);
  console.log(`  P99: ${summary.p99IngestionLatency}ms`);
  console.log('');
  console.log(`Error Rate: ${(summary.errorRate * 100).toFixed(2)}%`);
  console.log('═'.repeat(60));

  return {
    'load-test-results/iot-ingestion-summary.json': JSON.stringify(summary, null, 2),
  };
}
