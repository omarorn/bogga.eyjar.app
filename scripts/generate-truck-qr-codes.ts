/**
 * Generate Truck QR Codes Script
 *
 * Generates encrypted QR codes for all trucks and creates print-ready PDF
 *
 * Usage:
 *   npx tsx scripts/generate-truck-qr-codes.ts
 *
 * Environment variables required:
 *   QR_ENCRYPTION_KEY - Base64-encoded 32-byte encryption key
 *   DATABASE_URL - D1 database connection (or use wrangler local mode)
 */

import QRCode from 'qrcode';
import { encryptQRData, generateSalt, type QRPayload } from '../packages/workers/src/utils/qrEncryption';
import * as fs from 'fs';
import * as path from 'path';

// Configuration
const OUTPUT_DIR = path.join(__dirname, '../output/truck-qr-codes');
const QR_SIZE = 400; // pixels (10cm at 96 DPI for printing)

// Mock trucks for demonstration (replace with actual DB query)
const TRUCKS = [
  { truck_id: 'LG-001', name: 'Bíll 1' },
  { truck_id: 'LG-002', name: 'Bíll 2' },
  { truck_id: 'LG-003', name: 'Bíll 3' },
];

interface TruckQRData {
  truck_id: string;
  name: string;
  qr_payload: string;
  qr_image_data: string;
}

async function generateTruckQRCodes(): Promise<TruckQRData[]> {
  const encryptionKey = process.env.QR_ENCRYPTION_KEY;

  if (!encryptionKey) {
    throw new Error('QR_ENCRYPTION_KEY environment variable not set');
  }

  console.log('🚛 Generating truck QR codes...\n');

  // Create output directory
  if (!fs.existsSync(OUTPUT_DIR)) {
    fs.mkdirSync(OUTPUT_DIR, { recursive: true });
  }

  const results: TruckQRData[] = [];

  for (const truck of TRUCKS) {
    console.log(`Processing ${truck.truck_id} (${truck.name})...`);

    // Create QR payload
    const payload: QRPayload = {
      truck_id: truck.truck_id,
      issued_at: Date.now(),
      salt: generateSalt(),
    };

    // Encrypt payload
    const encryptedPayload = await encryptQRData(payload, encryptionKey);

    // Generate QR code image
    const qrImageData = await QRCode.toDataURL(encryptedPayload, {
      width: QR_SIZE,
      margin: 2,
      errorCorrectionLevel: 'H', // High error correction for durability
      color: {
        dark: '#000000',
        light: '#FFFFFF',
      },
    });

    // Save PNG file
    const pngPath = path.join(OUTPUT_DIR, `${truck.truck_id}.png`);
    const base64Data = qrImageData.replace(/^data:image\/png;base64,/, '');
    fs.writeFileSync(pngPath, base64Data, 'base64');

    results.push({
      truck_id: truck.truck_id,
      name: truck.name,
      qr_payload: encryptedPayload,
      qr_image_data: qrImageData,
    });

    console.log(`  ✓ Generated QR code: ${pngPath}`);
  }

  console.log(`\n✅ Generated ${results.length} QR codes\n`);

  return results;
}

async function generatePrintReadyHTML(trucks: TruckQRData[]): Promise<void> {
  const htmlPath = path.join(OUTPUT_DIR, 'print-ready.html');

  const html = `
<!DOCTYPE html>
<html lang="is">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Litla Gámaleigan - Bíla QR Kóðar</title>
  <style>
    @page {
      size: A4;
      margin: 2cm;
    }

    body {
      font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
      margin: 0;
      padding: 0;
    }

    .truck-card {
      page-break-after: always;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      padding: 2cm;
    }

    .truck-card:last-child {
      page-break-after: auto;
    }

    .truck-id {
      font-size: 48px;
      font-weight: bold;
      margin-bottom: 20px;
      color: #1a2b3a;
    }

    .truck-name {
      font-size: 24px;
      color: #6B4423;
      margin-bottom: 40px;
    }

    .qr-code {
      width: 10cm;
      height: 10cm;
      border: 3px solid #E89B3C;
      border-radius: 10px;
      padding: 10px;
      background: white;
      box-shadow: 0 4px 12px rgba(0,0,0,0.1);
      margin-bottom: 40px;
    }

    .instructions {
      text-align: center;
      max-width: 500px;
      background: #F5F0E8;
      padding: 20px;
      border-radius: 10px;
      border-left: 4px solid #E89B3C;
    }

    .instructions h3 {
      margin-top: 0;
      color: #1a2b3a;
      font-size: 20px;
    }

    .instructions ol {
      text-align: left;
      padding-left: 20px;
      line-height: 1.8;
    }

    .instructions li {
      margin-bottom: 10px;
    }

    .logo {
      font-size: 32px;
      font-weight: bold;
      color: #E89B3C;
      margin-bottom: 60px;
    }

    @media print {
      body {
        -webkit-print-color-adjust: exact;
        print-color-adjust: exact;
      }
    }
  </style>
</head>
<body>
  ${trucks.map(truck => `
    <div class="truck-card">
      <div class="logo">Litla Gámaleigan</div>
      <div class="truck-id">${truck.truck_id}</div>
      <div class="truck-name">${truck.name}</div>
      <img src="${truck.qr_image_data}" alt="QR Code for ${truck.truck_id}" class="qr-code" />
      <div class="instructions">
        <h3>Innskráning ökumanns</h3>
        <ol>
          <li>Skannaðu QR kóðann með símanum þínum</li>
          <li>Sláðu inn símanúmerið þitt</li>
          <li>Sláðu inn 6-stafa kóðann úr SMS</li>
        </ol>
      </div>
    </div>
  `).join('\n')}
</body>
</html>
  `.trim();

  fs.writeFileSync(htmlPath, html);

  console.log(`📄 Print-ready HTML: ${htmlPath}`);
  console.log(`   Open this file in a browser and print to PDF (Cmd/Ctrl+P)`);
  console.log(`   Recommended: Print at 100% scale, no margins\n`);
}

async function saveToDatabase(trucks: TruckQRData[]): Promise<void> {
  console.log('💾 Saving to database...\n');

  // Generate SQL insert statements
  const sqlPath = path.join(OUTPUT_DIR, 'truck_auth_seed.sql');

  const insertStatements = trucks.map(truck => `
INSERT INTO truck_auth (truck_id, qr_code_payload, qr_issued_at, created_at, updated_at)
VALUES ('${truck.truck_id}', '${truck.qr_payload}', datetime('now'), datetime('now'), datetime('now'));
  `.trim()).join('\n\n');

  const sql = `
-- Truck Auth Seed Data
-- Generated: ${new Date().toISOString()}
-- Trucks: ${trucks.length}

${insertStatements}

-- Verify insertion
SELECT truck_id, qr_issued_at, created_at FROM truck_auth;
  `.trim();

  fs.writeFileSync(sqlPath, sql);

  console.log(`📝 SQL seed file: ${sqlPath}`);
  console.log(`   Run with: npx wrangler d1 execute DB_NAME --local --file=${sqlPath}\n`);
}

// Main execution
async function main() {
  try {
    console.log('🚀 Truck QR Code Generation Script\n');
    console.log('=' .repeat(60) + '\n');

    // Generate QR codes
    const trucks = await generateTruckQRCodes();

    // Generate print-ready HTML
    await generatePrintReadyHTML(trucks);

    // Save SQL seed file
    await saveToDatabase(trucks);

    console.log('=' .repeat(60));
    console.log('✅ All done! Next steps:\n');
    console.log('1. Open output/truck-qr-codes/print-ready.html in browser');
    console.log('2. Print to PDF (one page per truck)');
    console.log('3. Laminate the printed QR codes');
    console.log('4. Attach to truck dashboards\n');

  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

main();
