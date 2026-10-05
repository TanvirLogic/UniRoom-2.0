const fs = require('fs');
const path = require('path');

const candidates = [
  path.resolve(__dirname, '..', 'firebase-service-account.json'),
  path.resolve(process.cwd(), 'firebase-service-account.json'),
  path.resolve(process.cwd(), 'backend', 'firebase-service-account.json'),
];

let targetFile = null;
for (const p of candidates) {
  if (fs.existsSync(p)) {
    targetFile = p;
    break;
  }
}

if (!targetFile) {
  console.error('❌ Could not find firebase-service-account.json in any expected folder.');
  process.exit(1);
}

try {
  const content = fs.readFileSync(targetFile, 'utf8');
  const parsed = JSON.parse(content);
  const minified = JSON.stringify(parsed);
  const base64 = Buffer.from(minified).toString('base64');

  console.log('\n================================================================');
  console.log('🔥 FIREBASE CREDENTIALS HELPER FOR RENDER DEPLOYMENT');
  console.log('================================================================');
  console.log(`Found Key: ${targetFile}`);
  console.log(`Project ID: ${parsed.project_id}`);
  console.log(`Client Email: ${parsed.client_email}`);
  console.log('\n--- OPTION A: Base64 String (RECOMMENDED FOR RENDER) ---');
  console.log('Key: FIREBASE_SERVICE_ACCOUNT_BASE64');
  console.log('Value:');
  console.log(base64);

  console.log('\n--- OPTION B: Minified JSON String ---');
  console.log('Key: FIREBASE_SERVICE_ACCOUNT_JSON');
  console.log('Value:');
  console.log(minified);

  console.log('\n================================================================\n');
} catch (err) {
  console.error('❌ Error processing firebase-service-account.json:', err.message);
  process.exit(1);
}
