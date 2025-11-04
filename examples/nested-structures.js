#!/usr/bin/env node

import { Encoder, encode, encodeToHex } from '../lib/encoder.js';
import { Decoder, decode } from '../lib/decoder.js';

console.log('=== Nested Structures Example ===\n');

// Example 1: Map inside a map
console.log('Example 1: Map with nested map');
console.log('Structure: {outer: 42, nested: {inner: 100, name: "test"}}');

const enc1 = new Encoder();
enc1.startMap(2);              // Start outer map with 2 entries

enc1.encodeString('outer');    // First key
enc1.encodeUint(42);           // First value (simple)

enc1.encodeString('nested');   // Second key
enc1.startMap(2);              // Second value is a MAP! (nested)
  enc1.encodeString('inner');  // Nested key 1
  enc1.encodeUint(100);        // Nested value 1
  enc1.encodeString('name');   // Nested key 2
  enc1.encodeString('test');   // Nested value 2
// No "end map" needed - decoder knows by counting

const hex1 = enc1.toHex();
console.log('Encoded:', hex1);
console.log('Decoded:', JSON.stringify(decode(hex1), null, 2));
console.log();

// Example 2: Array inside a map
console.log('Example 2: Map with array value');
console.log('Structure: {name: "Alice", scores: [10, 20, 30]}');

const enc2 = new Encoder();
enc2.startMap(2);              // Start map with 2 entries

enc2.encodeString('name');     // First key
enc2.encodeString('Alice');    // First value (simple)

enc2.encodeString('scores');   // Second key
enc2.startArray(3);            // Second value is an ARRAY! (nested)
  enc2.encodeUint(10);         // Array element 1
  enc2.encodeUint(20);         // Array element 2
  enc2.encodeUint(30);         // Array element 3

const hex2 = enc2.toHex();
console.log('Encoded:', hex2);
console.log('Decoded:', JSON.stringify(decode(hex2), null, 2));
console.log();

// Example 3: Map with mixed nested structures
console.log('Example 3: Complex nesting');
console.log('Structure: {id: 1, data: {tags: ["a", "b"], active: true}, count: 5}');

const enc3 = new Encoder();
enc3.startMap(3);                  // Outer map: 3 entries

enc3.encodeString('id');           // Entry 1
enc3.encodeUint(1);

enc3.encodeString('data');         // Entry 2: key
enc3.startMap(2);                  // Entry 2: value is a map
  enc3.encodeString('tags');       //   Nested entry 1: key
  enc3.startArray(2);              //   Nested entry 1: value is an array
    enc3.encodeString('a');        //     Array element 1
    enc3.encodeString('b');        //     Array element 2
  enc3.encodeString('active');     //   Nested entry 2: key
  enc3.encodeBool(true);           //   Nested entry 2: value

enc3.encodeString('count');        // Entry 3
enc3.encodeUint(5);

const hex3 = enc3.toHex();
console.log('Encoded:', hex3);
console.log('Decoded:', JSON.stringify(decode(hex3), null, 2));
console.log();

// Example 4: How the decoder handles it
console.log('Example 4: Step-by-step decoding of nested map');
const data = enc1.getEncoded(); // Use example 1 data
const dec = new Decoder(data);

console.log('Step 1: Decode outer map length');
const outerLen = dec.decodeMapLength();
console.log('  Outer map has', outerLen, 'entries');

console.log('\nStep 2: Decode first entry');
const key1 = dec.decodeString();
console.log('  Key:', key1);
const val1 = dec.decodeUint();
console.log('  Value:', val1);

console.log('\nStep 3: Decode second entry');
const key2 = dec.decodeString();
console.log('  Key:', key2);

console.log('\nStep 4: Check type of second value');
const category = dec.peekCategory();
console.log('  Value type:', category);

console.log('\nStep 5: Decode nested map');
const nestedLen = dec.decodeMapLength();
console.log('  Nested map has', nestedLen, 'entries');

const nestedKey1 = dec.decodeString();
const nestedVal1 = dec.decodeUint();
console.log('  Nested entry 1:', nestedKey1, '=', nestedVal1);

const nestedKey2 = dec.decodeString();
const nestedVal2 = dec.decodeString();
console.log('  Nested entry 2:', nestedKey2, '=', nestedVal2);

console.log('\nStep 6: Check if more data');
console.log('  Has more data:', dec.hasMore());
console.log();

// Example 5: What happens if you don't know the structure?
console.log('Example 5: Generic decoding of unknown nested structure');
const dec2 = new Decoder(enc3.getEncoded());

function decodeGeneric(dec, indent = '') {
    const cat = dec.peekCategory();

    if (cat === 'MAP') {
        const len = dec.decodeMapLength();
        console.log(indent + 'Map with', len, 'entries:');
        for (let i = 0; i < len; i++) {
            const key = dec.decodeString();
            console.log(indent + '  Key:', key);
            console.log(indent + '  Value type:', dec.peekCategory());
            decodeGeneric(dec, indent + '    ');
        }
    } else if (cat === 'ARRAY') {
        const len = dec.decodeArrayLength();
        console.log(indent + 'Array with', len, 'elements:');
        for (let i = 0; i < len; i++) {
            console.log(indent + '  Element', i, 'type:', dec.peekCategory());
            decodeGeneric(dec, indent + '    ');
        }
    } else if (cat === 'UINT') {
        console.log(indent + 'Uint:', dec.decodeUint());
    } else if (cat === 'STRING') {
        console.log(indent + 'String:', dec.decodeString());
    } else if (cat === 'BOOL') {
        console.log(indent + 'Bool:', dec.decodeBool());
    } else {
        console.log(indent + 'Other type:', cat);
        dec.skip();
    }
}

decodeGeneric(dec2);
console.log();

console.log('=== Key Takeaways ===');
console.log('1. When you startMap(N), you must encode exactly N key-value pairs');
console.log('2. Any value can itself be a map, array, or simple type');
console.log('3. The decoder counts entries to know when a nested structure ends');
console.log('4. No explicit "end map" or "end array" markers needed');
console.log('5. Use peekCategory() to inspect types before decoding');
