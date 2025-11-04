#!/usr/bin/env node

import { Encoder, encode } from '../lib/encoder.js';
import { decode, Decoder, decodeAll } from '../lib/helpers.js';

console.log('=== How decode() Handles Elements After First Map ===\n');

// Create data: Map, then more items after it
const enc = new Encoder();

// First: a map with 2 entries
enc.startMap(2);
enc.encodeString('a');
enc.encodeUint(1);
enc.encodeString('b');
enc.encodeUint(2);

// Then: more items after the map
enc.encodeUint(42);
enc.encodeString('hello');
enc.encodeBool(true);

const encoded = enc.getEncoded();

console.log('Encoded data structure:');
console.log('  [MAP{a:1, b:2}] [42] ["hello"] [true]');
console.log('  └─ first map ─┘  └─── after map ────┘');
console.log();

console.log('Encoded hex:', '0x' + encoded.toString('hex'));
console.log('Total bytes:', encoded.length);
console.log();

// Test 1: decode() - only decodes the FIRST item
console.log('─'.repeat(50));
console.log('Test 1: decode() - Decodes ONLY the first item');
console.log('─'.repeat(50));

const result1 = decode(encoded);
console.log('Result:', result1);
console.log('Type:', typeof result1);
console.log('Is map?', typeof result1 === 'object' && !Array.isArray(result1));
console.log();
console.log('⚠️  decode() stopped after the first map!');
console.log('    It did NOT decode 42, "hello", true');
console.log();

// Test 2: decodeAll() - decodes ALL items sequentially
console.log('─'.repeat(50));
console.log('Test 2: decodeAll() - Decodes ALL items');
console.log('─'.repeat(50));

const result2 = decodeAll(encoded);
console.log('Result:', result2);
console.log('Type:', Array.isArray(result2) ? 'array' : typeof result2);
console.log('Length:', result2.length);
console.log();
console.log('✓ decodeAll() got everything:');
console.log('  [0]:', result2[0], '← the map');
console.log('  [1]:', result2[1], '← after map');
console.log('  [2]:', result2[2], '← after map');
console.log('  [3]:', result2[3], '← after map');
console.log();

// Test 3: Manual decoding with Decoder
console.log('─'.repeat(50));
console.log('Test 3: Manual Decoder - Step by step');
console.log('─'.repeat(50));

const dec = new Decoder(encoded);

console.log('Step 1: Decode first item (map)');
const map = dec.decode();
console.log('  Result:', map);
console.log('  hasMore():', dec.hasMore());

console.log('\nStep 2: Decode second item');
const num = dec.decode();
console.log('  Result:', num);
console.log('  hasMore():', dec.hasMore());

console.log('\nStep 3: Decode third item');
const str = dec.decode();
console.log('  Result:', str);
console.log('  hasMore():', dec.hasMore());

console.log('\nStep 4: Decode fourth item');
const bool = dec.decode();
console.log('  Result:', bool);
console.log('  hasMore():', dec.hasMore());
console.log();

// Test 4: What if the map was wrapped in an array?
console.log('─'.repeat(50));
console.log('Test 4: Map wrapped in array vs not wrapped');
console.log('─'.repeat(50));

// Not wrapped (our example)
const notWrapped = encode({ a: 1 });
console.log('Not wrapped:');
console.log('  Encoded:', '0x' + notWrapped.toString('hex'));
console.log('  decode():', decode(notWrapped));

// After the map
const enc2 = new Encoder();
enc2.startMap(2);
enc2.encodeString('a');
enc2.encodeUint(1);
enc2.encodeString('b');
enc2.encodeUint(2);
enc2.encodeUint(42);
const withExtra = enc2.getEncoded();

console.log('\nMap + extra (not wrapped):');
console.log('  Encoded:', '0x' + withExtra.toString('hex'));
console.log('  decode():', decode(withExtra), '← Only got the map!');
console.log('  decodeAll():', decodeAll(withExtra), '← Got everything!');

// Wrapped in array
const wrapped = encode([{ a: 1, b: 2 }, 42]);
console.log('\nWrapped in array:');
console.log('  Encoded:', '0x' + wrapped.toString('hex'));
console.log('  decode():', decode(wrapped), '← Got everything!');
console.log();

// Test 5: Common patterns
console.log('─'.repeat(50));
console.log('Test 5: Common encoding patterns');
console.log('─'.repeat(50));

console.log('\nPattern 1: Single value');
const single = encode({ test: 42 });
console.log('  decode():', decode(single));
console.log('  ✓ Works perfectly');

console.log('\nPattern 2: Array of items');
const array = encode([{ a: 1 }, 42, 'hello']);
console.log('  decode():', decode(array));
console.log('  ✓ Gets all items in the array');

console.log('\nPattern 3: Sequential items (NOT in array)');
const sequential = Buffer.concat([
    encode({ a: 1 }),
    encode(42),
    encode('hello')
]);
console.log('  decode():', decode(sequential));
console.log('  ⚠️  Only gets first item!');
console.log('  decodeAll():', decodeAll(sequential));
console.log('  ✓ Use decodeAll() for sequential data');
console.log();

// Summary
console.log('='.repeat(50));
console.log('KEY INSIGHTS:');
console.log('='.repeat(50));
console.log();
console.log('1. decode() decodes ONLY THE FIRST item in the byte stream');
console.log('   - Stops after the first complete value');
console.log('   - Ignores anything after it');
console.log();
console.log('2. decodeAll() decodes ALL items sequentially');
console.log('   - Keeps decoding until no more data');
console.log('   - Returns an array of all values');
console.log();
console.log('3. If you want multiple items decoded, you have TWO options:');
console.log('   a) Wrap them in an array when encoding:');
console.log('      encode([item1, item2, item3])');
console.log('      Then: decode() returns all in one array');
console.log();
console.log('   b) Encode them sequentially:');
console.log('      encode(item1) + encode(item2) + encode(item3)');
console.log('      Then: decodeAll() returns all items');
console.log();
console.log('4. Manual control:');
console.log('   const dec = new Decoder(data);');
console.log('   while (dec.hasMore()) {');
console.log('       const item = dec.decode();');
console.log('   }');
