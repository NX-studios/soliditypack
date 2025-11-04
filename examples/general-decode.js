#!/usr/bin/env node

import { encode, encodeToHex } from '../lib/encoder.js';
import {
    decode,
    decodeAll,
    decodeWithType,
    decodePretty,
    decodeStats,
    extractField,
    roundTrip,
    decodeWithValidation
} from '../lib/helpers.js';

console.log('=== General Decode Function Examples ===\n');

// Example 1: Basic decode - automatically detects all types
console.log('Example 1: Basic decode() - Auto-detects types');
console.log('─'.repeat(50));

const data1 = { test: 42, test2: [] };
const encoded1 = encode(data1);

console.log('Original:', data1);
console.log('Encoded:', '0x' + encoded1.toString('hex'));
console.log('Decoded:', decode(encoded1));
console.log('✓ Automatically decoded map with empty array\n');

// Example 2: Decode complex nested structure
console.log('Example 2: Decode complex nested data');
console.log('─'.repeat(50));

const complex = {
    user: {
        name: 'Alice',
        age: 30,
        roles: ['admin', 'user']
    },
    active: true,
    balance: 1000000n,
    tags: null
};

const encoded2 = encode(complex);
console.log('Original:', JSON.stringify(complex, (k, v) => typeof v === 'bigint' ? v.toString() : v, 2));
console.log('Encoded size:', encoded2.length, 'bytes');
console.log('Decoded:', decode(encoded2));
console.log('✓ Handles nested objects, arrays, BigInt, null\n');

// Example 3: Decode heterogeneous array
console.log('Example 3: Decode mixed-type array');
console.log('─'.repeat(50));

const mixed = [42, 'hello', true, null, { key: 'value' }, [1, 2, 3]];
const encoded3 = encode(mixed);

console.log('Original:', mixed);
console.log('Decoded:', decode(encoded3));
console.log('✓ Handles arrays with different types\n');

// Example 4: Decode multiple sequential values
console.log('Example 4: Decode multiple sequential values with decodeAll()');
console.log('─'.repeat(50));

const enc4 = encode({ a: 1 });
const enc5 = encode(42);
const enc6 = encode('hello');
const sequential = Buffer.concat([enc4, enc5, enc6]);

console.log('Encoded three separate items sequentially');
console.log('Using decodeAll():', decodeAll(sequential));
console.log('✓ Decodes all values in sequence\n');

// Example 5: Decode with type information
console.log('Example 5: Decode with type inspection');
console.log('─'.repeat(50));

const testValues = [
    encode(42),
    encode('test'),
    encode(true),
    encode([1, 2, 3]),
    encode({ key: 'value' }),
    encode(null)
];

testValues.forEach((val, i) => {
    const { value, type } = decodeWithType(val);
    console.log(`  Value ${i}: ${JSON.stringify(value)} (type: ${type})`);
});
console.log();

// Example 6: Pretty printing
console.log('Example 6: Pretty print with decodePretty()');
console.log('─'.repeat(50));

const prettyData = {
    transaction: {
        from: '0x1234567890123456789012345678901234567890',
        to: '0x0987654321098765432109876543210987654321',
        amount: 1000000000000000000n,
        timestamp: 1234567890,
        confirmed: true
    }
};

const encoded6 = encode(prettyData);
console.log('Pretty printed:');
console.log(decodePretty(encoded6));
console.log();

// Example 7: Extract specific field
console.log('Example 7: Extract specific field with extractField()');
console.log('─'.repeat(50));

const userData = { name: 'Bob', age: 25, email: 'bob@example.com' };
const encoded7 = encode(userData);

console.log('Original:', userData);
console.log('Extract "name":', extractField(encoded7, 'name'));
console.log('Extract "age":', extractField(encoded7, 'age'));
console.log('✓ Directly extract fields without decoding everything\n');

// Example 8: Decode with statistics
console.log('Example 8: Get statistics with decodeStats()');
console.log('─'.repeat(50));

const statsData = {
    items: [1, 2, 3, 4, 5],
    metadata: {
        count: 5,
        tags: ['a', 'b', 'c']
    },
    active: true
};

const encoded8 = encode(statsData);
const stats = decodeStats(encoded8);

console.log('Data:', JSON.stringify(statsData));
console.log('Statistics:');
console.log('  Total bytes:', stats.totalBytes);
console.log('  Max depth:', stats.depth);
console.log('  Arrays:', stats.arrays);
console.log('  Maps:', stats.maps);
console.log('  Primitives:', stats.primitives);
console.log('  Type breakdown:', stats.types);
console.log();

// Example 9: Round-trip validation
console.log('Example 9: Round-trip encode/decode');
console.log('─'.repeat(50));

const original = { test: 123, nested: { value: true } };
const trip = roundTrip(original);

console.log('Original:', JSON.stringify(trip.original));
console.log('Encoded:', trip.encoded);
console.log('Size:', trip.bytesSize, 'bytes');
console.log('Decoded:', JSON.stringify(trip.decoded));
console.log('Match:', trip.matches ? '✓' : '✗');
console.log();

// Example 10: Decode with validation
console.log('Example 10: Decode with schema validation');
console.log('─'.repeat(50));

const validData = { name: 'Alice', age: 30, email: 'alice@example.com' };
const encoded10 = encode(validData);

try {
    const schema = {
        type: 'object',
        required: ['name', 'age']
    };

    const validated = decodeWithValidation(encoded10, schema);
    console.log('✓ Validation passed:', validated);
} catch (e) {
    console.log('✗ Validation failed:', e.message);
}

// Test with invalid data
try {
    const invalidEncoded = encode({ name: 'Bob' }); // missing 'age'
    const schema = {
        type: 'object',
        required: ['name', 'age']
    };

    decodeWithValidation(invalidEncoded, schema);
} catch (e) {
    console.log('✓ Correctly caught missing field:', e.message);
}
console.log();

// Example 11: Decode from hex string
console.log('Example 11: Decode from hex string');
console.log('─'.repeat(50));

const hexString = '0x82a4746573742aa5746573743290';
console.log('Hex input:', hexString);
console.log('Decoded:', decode(hexString));
console.log('✓ Works with hex strings (with or without 0x prefix)\n');

// Example 12: Real-world example - decode transaction
console.log('Example 12: Real-world transaction decoding');
console.log('─'.repeat(50));

const transaction = {
    type: 'transfer',
    from: '0x742d35cC6634c0532925A3b844bc9E7595F0beB1',
    to: '0x1234567890123456789012345678901234567890',
    amount: 1500000000000000000n, // 1.5 ETH
    gas: 21000,
    nonce: 42,
    data: Buffer.from('hello', 'utf8'),
    metadata: {
        timestamp: Date.now(),
        confirmed: false,
        tags: ['pending', 'high-priority']
    }
};

const txEncoded = encode(transaction);
console.log('Transaction size:', txEncoded.length, 'bytes');
console.log('Encoded:', '0x' + txEncoded.toString('hex'));
console.log('\nDecoded transaction:');
const decoded = decode(txEncoded);
console.log(JSON.stringify(decoded, (k, v) => {
    if (typeof v === 'bigint') return v.toString() + 'n';
    if (Buffer.isBuffer(v)) return '<Buffer ' + v.toString('hex') + '>';
    return v;
}, 2));
console.log();

console.log('='.repeat(50));
console.log('SUMMARY: The decode() function:');
console.log('✓ Automatically detects all types');
console.log('✓ Handles nested structures');
console.log('✓ Works with BigInt, Buffer, null');
console.log('✓ Decodes maps as objects, arrays as arrays');
console.log('✓ Preserves Ethereum addresses and bytes32');
console.log('✓ Can decode from Buffer or hex string');
console.log('✓ Returns native JavaScript types');
