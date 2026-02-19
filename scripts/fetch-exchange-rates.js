#!/usr/bin/env node
/**
 * Fetch Exchange Rates from Seðlabanki Íslands (Central Bank of Iceland)
 *
 * Fetches latest USD and EUR exchange rates relative to ISK.
 * Data source: https://sedlabanki.is/gagnatorg/xml-gogn/
 *
 * Usage:
 *   node scripts/fetch-exchange-rates.js
 *   node scripts/fetch-exchange-rates.js --json
 *   node scripts/fetch-exchange-rates.js --export
 */

const SEDLABANKI_URL = 'https://sedlabanki.is/xmltimeseries/Default.aspx?DagsFra=LATEST&GroupID=9&Type=xml';

// Time Series IDs for mid-rates (miðgengi)
const CURRENCY_IDS = {
  USD: '4055',  // Bandaríkjadalur, skráð miðgengi
  EUR: '4064',  // Evra, skráð miðgengi
  GBP: '4067',  // Breskt pund, skráð miðgengi
  DKK: '4061',  // Dönsk króna, skráð miðgengi
  NOK: '4079',  // Norsk króna, skráð miðgengi
  SEK: '4085',  // Sænsk króna, skráð miðgengi
};

async function fetchExchangeRates() {
  console.log('Fetching exchange rates from Seðlabanki Íslands...\n');

  try {
    const response = await fetch(SEDLABANKI_URL);

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }

    const xml = await response.text();

    // Parse rates from XML
    const rates = {};

    for (const [currency, id] of Object.entries(CURRENCY_IDS)) {
      const regex = new RegExp(
        `<TimeSeries ID="${id}">[\\s\\S]*?<Value>([\\d.]+)</Value>[\\s\\S]*?</TimeSeries>`,
        'i'
      );
      const match = xml.match(regex);

      if (match) {
        rates[currency] = parseFloat(match[1]);
      }
    }

    // Extract date from any entry
    const dateMatch = xml.match(/<Date>(\d{1,2}\/\d{1,2}\/\d{4})/);
    const dateStr = dateMatch ? dateMatch[1] : new Date().toLocaleDateString('en-US');

    return {
      date: dateStr,
      rates,
      source: 'Seðlabanki Íslands',
      url: SEDLABANKI_URL
    };
  } catch (error) {
    console.error('Error fetching rates:', error.message);

    // Return fallback rates (as of January 2026)
    console.log('\nUsing fallback rates...\n');
    return {
      date: '1/6/2026',
      rates: {
        USD: 125.74,
        EUR: 147.2,
        GBP: 157.5,
        DKK: 19.75,
        NOK: 11.2,
        SEK: 11.5
      },
      source: 'Fallback (Seðlabanki offline)',
      url: SEDLABANKI_URL
    };
  }
}

function formatISK(amount) {
  return amount.toLocaleString('is-IS') + ' kr';
}

function convertToISK(usdAmount, usdRate) {
  return usdAmount * usdRate;
}

function convertFromISK(iskAmount, usdRate) {
  return iskAmount / usdRate;
}

async function main() {
  const args = process.argv.slice(2);
  const outputJson = args.includes('--json');
  const exportConsts = args.includes('--export');

  const data = await fetchExchangeRates();

  if (outputJson) {
    console.log(JSON.stringify(data, null, 2));
    return;
  }

  if (exportConsts) {
    // Output TypeScript constants for embedding
    console.log(`// Exchange rates as of ${data.date}`);
    console.log(`// Source: ${data.source}`);
    console.log(`export const EXCHANGE_RATES = {`);
    for (const [currency, rate] of Object.entries(data.rates)) {
      console.log(`  ${currency}: ${rate}, // 1 ${currency} = ${rate} ISK`);
    }
    console.log(`};`);
    console.log(`export const EXCHANGE_RATE_DATE = '${data.date}';`);
    return;
  }

  // Human-readable output
  console.log(`Exchange Rates (${data.date})`);
  console.log(`Source: ${data.source}`);
  console.log('─'.repeat(50));
  console.log('');

  for (const [currency, rate] of Object.entries(data.rates)) {
    console.log(`1 ${currency} = ${formatISK(rate)}`);
  }

  console.log('');
  console.log('─'.repeat(50));
  console.log('Example conversions (USD):');
  console.log('');

  const usdRate = data.rates.USD;
  const examples = [100, 1000, 10000, 50000];

  for (const usd of examples) {
    const isk = convertToISK(usd, usdRate);
    console.log(`  $${usd.toLocaleString()} = ${formatISK(isk)}`);
  }

  console.log('');
  console.log('ISK to USD:');

  const iskExamples = [10000, 50000, 100000, 1000000];
  for (const isk of iskExamples) {
    const usd = convertFromISK(isk, usdRate);
    console.log(`  ${formatISK(isk)} = $${usd.toFixed(2)}`);
  }
}

// Export for use as module
module.exports = { fetchExchangeRates, formatISK, convertToISK, convertFromISK };

// Run if called directly
if (require.main === module) {
  main().catch(console.error);
}
