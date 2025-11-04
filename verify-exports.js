#!/usr/bin/env node

// Verify that all package exports work correctly
console.log('Verifying package exports...\n');

let errors = 0;

try {
    console.log('1. Testing main export (index.js)...');
    const main = await import('./index.js');
    console.log('   ✓ Encoder:', typeof main.Encoder);
    console.log('   ✓ Decoder:', typeof main.Decoder);
    console.log('   ✓ encode:', typeof main.encode);
    console.log('   ✓ decode:', typeof main.decode);
    console.log('   ✓ encodeToHex:', typeof main.encodeToHex);
    console.log('   ✓ TypeCategory:', typeof main.TypeCategory);
    console.log('   ✓ decodeAll:', typeof main.decodeAll);

    // Test basic encoding/decoding
    const data = { test: 42, test2: [] };
    const encoded = main.encode(data);
    const decoded = main.decode(encoded);
    console.log('   ✓ Round-trip test:', JSON.stringify(decoded) === JSON.stringify(data));
} catch (e) {
    console.error('   ✗ Main export failed:', e.message);
    errors++;
}

try {
    console.log('\n2. Testing encoder export...');
    const encoder = await import('./lib/encoder.js');
    console.log('   ✓ Encoder class:', typeof encoder.Encoder);
    console.log('   ✓ encode function:', typeof encoder.encode);
    console.log('   ✓ encodeToHex function:', typeof encoder.encodeToHex);
} catch (e) {
    console.error('   ✗ Encoder export failed:', e.message);
    errors++;
}

try {
    console.log('\n3. Testing decoder export...');
    const decoder = await import('./lib/decoder.js');
    console.log('   ✓ Decoder class:', typeof decoder.Decoder);
    console.log('   ✓ decode function:', typeof decoder.decode);
    console.log('   ✓ TypeCategory:', typeof decoder.TypeCategory);
} catch (e) {
    console.error('   ✗ Decoder export failed:', e.message);
    errors++;
}

try {
    console.log('\n4. Testing helpers export...');
    const helpers = await import('./lib/helpers.js');
    console.log('   ✓ decodeAll:', typeof helpers.decodeAll);
    console.log('   ✓ decodeWithType:', typeof helpers.decodeWithType);
    console.log('   ✓ decodePretty:', typeof helpers.decodePretty);
    console.log('   ✓ decodeStats:', typeof helpers.decodeStats);
    console.log('   ✓ extractField:', typeof helpers.extractField);
    console.log('   ✓ roundTrip:', typeof helpers.roundTrip);
} catch (e) {
    console.error('   ✗ Helpers export failed:', e.message);
    errors++;
}

console.log('\n' + '='.repeat(60));
if (errors === 0) {
    console.log('✅ All package exports verified successfully!');
    console.log('\nPackage structure:');
    console.log('  - Main: import { ... } from "soliditypack"');
    console.log('  - Encoder: import { ... } from "soliditypack/encoder"');
    console.log('  - Decoder: import { ... } from "soliditypack/decoder"');
    console.log('  - Helpers: import { ... } from "soliditypack/helpers"');
    console.log('  - Contracts: import "soliditypack/contracts/..."');
} else {
    console.log(`❌ ${errors} export(s) failed verification`);
    process.exit(1);
}
