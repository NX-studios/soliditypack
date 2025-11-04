#!/usr/bin/env node

import { encode, encodeToHex, Encoder } from '../lib/encoder.js';
import { decode } from '../lib/decoder.js';

console.log('====================================');
console.log('Encoding: {test: 42, test2: []}');
console.log('====================================\n');

// The requested data
const data = { test: 42, test2: [] };

// Method 1: Auto-encode
console.log('Method 1: Auto-encode');
const encoded1 = encode(data);
console.log('  Result:', '0x' + encoded1.toString('hex'));
console.log('  Size:', encoded1.length, 'bytes\n');

// Method 2: Direct hex
console.log('Method 2: Direct hex');
const hex = encodeToHex(data);
console.log('  Result:', hex);
console.log('  Size:', (hex.length - 2) / 2, 'bytes\n');

// Method 3: Manual encoding
console.log('Method 3: Manual encoding with Encoder class');
const enc = new Encoder();
enc.startMap(2);           // Map with 2 entries
enc.encodeString('test');  // Key: "test"
enc.encodeUint(42);        // Value: 42
enc.encodeString('test2'); // Key: "test2"
enc.startArray(0);         // Empty array value
const manual = enc.toHex();
console.log('  Result:', manual);
console.log('  Size:', enc.pos, 'bytes\n');

// Verify all methods produce the same result
console.log('Verification:');
const hex1 = '0x' + encoded1.toString('hex');
console.log('  Method 1 === Method 2:', hex1 === hex);
console.log('  Method 2 === Method 3:', hex === manual);
console.log('  All methods match:', hex1 === hex && hex === manual);
console.log();

// Decode to verify
console.log('Decoding verification:');
const decoded = decode(hex);
console.log('  Decoded:', JSON.stringify(decoded));
console.log('  Matches original:', JSON.stringify(decoded) === JSON.stringify(data));
console.log();

// Breakdown of encoding
console.log('Encoding breakdown:');
const bytes = Buffer.from(hex.slice(2), 'hex');
console.log('  Hex:', hex);
console.log('  Bytes:', Array.from(bytes).map(b => '0x' + b.toString(16).padStart(2, '0')).join(' '));
console.log();
console.log('  0x82 - fixmap with 2 entries');
console.log('  0xa4 - fixstr with 4 characters');
console.log('  0x74 0x65 0x73 0x74 - "test" in UTF-8');
console.log('  0x2a - fixint 42 (decimal)');
console.log('  0xa5 - fixstr with 5 characters');
console.log('  0x74 0x65 0x73 0x74 0x32 - "test2" in UTF-8');
console.log('  0x90 - fixarray with 0 elements (empty array)');
console.log();

console.log('✅ Ready to use in Solidity!');
console.log('   Copy this hex value: ' + hex);
console.log('   Or use: hex"' + hex.slice(2) + '"');
