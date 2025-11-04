#!/usr/bin/env node

import { Encoder } from '../lib/encoder.js';
import { Decoder, decode } from '../lib/decoder.js';

console.log('=== Sequential Encoding: Data After a Map ===\n');

// Example 1: Map, then more data after it
console.log('Example 1: Encode map with 2 entries, then encode more items after');
console.log('Structure: Map{a:1, b:2}, then 42, then "hello"\n');

const enc1 = new Encoder();

// Encode a map with 2 entries
enc1.startMap(2);
enc1.encodeString('a');
enc1.encodeUint(1);
enc1.encodeString('b');
enc1.encodeUint(2);
// Map is now complete (2 entries encoded)

// Now encode MORE items AFTER the map
enc1.encodeUint(42);
enc1.encodeString('hello');

const encoded1 = enc1.getEncoded();
console.log('Encoded hex:', '0x' + encoded1.toString('hex'));
console.log('Encoded bytes:', encoded1.length, 'bytes');
console.log();

// Now let's decode it step by step
console.log('Decoding step by step:');
const dec1 = new Decoder(encoded1);

console.log('Step 1: Decode the map');
const mapLen = dec1.decodeMapLength();
console.log('  Map length:', mapLen);

const obj = {};
for (let i = 0; i < mapLen; i++) {
    const key = dec1.decodeString();
    const value = dec1.decodeUint();
    obj[key] = value;
    console.log(`  Entry ${i + 1}: ${key} = ${value}`);
}
console.log('  Map complete:', JSON.stringify(obj));

console.log('\nStep 2: Check if there\'s more data after the map');
console.log('  Has more data:', dec1.hasMore());

console.log('\nStep 3: Decode items after the map');
const afterMap1 = dec1.decodeUint();
console.log('  Item 1 after map:', afterMap1);

const afterMap2 = dec1.decodeString();
console.log('  Item 2 after map:', afterMap2);

console.log('\nStep 4: Check if there\'s more data');
console.log('  Has more data:', dec1.hasMore());
console.log();

// Example 2: Array containing a map, then more items
console.log('='.repeat(50));
console.log('Example 2: Array containing [map, 42, "test"]');
console.log('The map is INSIDE the array, then other items follow\n');

const enc2 = new Encoder();

enc2.startArray(3);        // Array with 3 elements

// Element 1: a map
enc2.startMap(2);
enc2.encodeString('x');
enc2.encodeUint(10);
enc2.encodeString('y');
enc2.encodeUint(20);

// Element 2: a number
enc2.encodeUint(42);

// Element 3: a string
enc2.encodeString('test');

const encoded2 = enc2.getEncoded();
console.log('Encoded hex:', '0x' + encoded2.toString('hex'));

// Decode with auto-decoder
const decoded2 = decode(encoded2);
console.log('Auto-decoded:', JSON.stringify(decoded2, null, 2));
console.log();

// Example 3: What if you declare startMap(2) but encode 3 entries?
console.log('='.repeat(50));
console.log('Example 3: What if you mismatch the count?');
console.log('Declare startMap(2) but encode 3 key-value pairs\n');

const enc3 = new Encoder();

enc3.startMap(2);          // Say there are 2 entries
enc3.encodeString('first');
enc3.encodeUint(1);
enc3.encodeString('second');
enc3.encodeUint(2);
// Map should be complete now according to our declaration

// But let's encode a THIRD entry
enc3.encodeString('third');
enc3.encodeUint(3);

const encoded3 = enc3.getEncoded();
console.log('Encoded hex:', '0x' + encoded3.toString('hex'));

// Now decode it
console.log('\nDecoding:');
const dec3 = new Decoder(encoded3);

console.log('Step 1: Decode map (declared length: 2)');
const mapLen3 = dec3.decodeMapLength();
console.log('  Map length:', mapLen3);

const obj3 = {};
for (let i = 0; i < mapLen3; i++) {
    const key = dec3.decodeString();
    const value = dec3.decodeUint();
    obj3[key] = value;
    console.log(`  Entry ${i + 1}: ${key} = ${value}`);
}

console.log('  Map decoded:', JSON.stringify(obj3));
console.log('\nStep 2: Check for more data');
console.log('  Has more data:', dec3.hasMore());

if (dec3.hasMore()) {
    console.log('\nStep 3: The "third" entry is OUTSIDE the map!');
    console.log('  Next type:', dec3.peekCategory());
    const extraKey = dec3.decodeString();
    console.log('  Extra key:', extraKey);
    const extraValue = dec3.decodeUint();
    console.log('  Extra value:', extraValue);
    console.log('\n  ⚠️  The third entry was encoded as separate data, not part of the map!');
}
console.log();

// Example 4: Correct way to have data after a map
console.log('='.repeat(50));
console.log('Example 4: Proper way - wrap everything in an array or outer structure\n');

const enc4 = new Encoder();

// Option 1: Array containing [map, other data]
enc4.startArray(3);        // Array with 3 items
enc4.startMap(2);          // Item 1: a map
enc4.encodeString('a');
enc4.encodeUint(1);
enc4.encodeString('b');
enc4.encodeUint(2);
enc4.encodeUint(42);       // Item 2: number
enc4.encodeString('hello'); // Item 3: string

const encoded4a = enc4.getEncoded();
console.log('Option 1: Array containing [map, 42, "hello"]');
console.log('Encoded:', '0x' + encoded4a.toString('hex'));
console.log('Decoded:', JSON.stringify(decode(encoded4a), null, 2));
console.log();

// Option 2: Outer map containing inner map
const enc5 = new Encoder();
enc5.startMap(3);          // Outer map with 3 entries
enc5.encodeString('data'); // Entry 1
enc5.startMap(2);          // Value is a map
enc5.encodeString('a');
enc5.encodeUint(1);
enc5.encodeString('b');
enc5.encodeUint(2);
enc5.encodeString('number'); // Entry 2
enc5.encodeUint(42);
enc5.encodeString('text');   // Entry 3
enc5.encodeString('hello');

const encoded5 = enc5.getEncoded();
console.log('Option 2: Outer map {data: {a:1, b:2}, number: 42, text: "hello"}');
console.log('Encoded:', '0x' + encoded5.toString('hex'));
console.log('Decoded:', JSON.stringify(decode(encoded5), null, 2));
console.log();

console.log('='.repeat(50));
console.log('KEY INSIGHTS:');
console.log('1. When you startMap(2), the decoder reads exactly 2 key-value pairs');
console.log('2. Anything you encode AFTER those 2 pairs is separate data');
console.log('3. The data is sequential in the byte stream');
console.log('4. If you declare 2 but encode 3 pairs, the 3rd becomes separate data');
console.log('5. Usually you want to wrap everything in an outer array or map');
