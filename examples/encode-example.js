import { encode, encodeToHex, Encoder } from '../lib/encoder.js';
import { decode, Decoder } from '../lib/decoder.js';

console.log('=== SolidityPack Encoding Examples ===\n');

// Example 1: The requested object {test: 42, test2: []}
console.log('Example 1: {test: 42, test2: []}');
const obj1 = { test: 42, test2: [] };
const encoded1 = encode(obj1);
console.log('Encoded (hex):', '0x' + encoded1.toString('hex'));
console.log('Encoded (bytes):', encoded1);
console.log('Decoded:', decode(encoded1));
console.log();

// Example 2: Using encodeToHex helper
console.log('Example 2: Using encodeToHex helper');
const hex = encodeToHex({ test: 42, test2: [] });
console.log('Hex:', hex);
console.log('Decoded:', decode(hex));
console.log();

// Example 3: More complex object
console.log('Example 3: Complex nested object');
const obj2 = {
    name: 'Alice',
    age: 30,
    balance: 1000000n,
    addresses: [
        '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb1',
        '0x1234567890123456789012345678901234567890'
    ],
    metadata: {
        active: true,
        tags: ['user', 'premium'],
        score: null
    }
};
const encoded2 = encode(obj2);
console.log('Object:', JSON.stringify(obj2, (k, v) => typeof v === 'bigint' ? v.toString() : v, 2));
console.log('Encoded (hex):', '0x' + encoded2.toString('hex'));
console.log('Size:', encoded2.length, 'bytes');
console.log('Decoded:', decode(encoded2));
console.log();

// Example 4: Manual encoding with Encoder class
console.log('Example 4: Manual encoding');
const enc = new Encoder();
enc.startMap(2);
enc.encodeString('test');
enc.encodeUint(42);
enc.encodeString('test2');
enc.encodeArray([]);
console.log('Manually encoded hex:', enc.toHex());
console.log('Decoded:', decode(enc.getEncoded()));
console.log();

// Example 5: Different data types
console.log('Example 5: Different data types');
const types = {
    bool: true,
    uint8: 255,
    uint256: 123456789012345678901234567890n,
    negativeInt: -42,
    string: 'Hello, World!',
    bytes: Buffer.from('deadbeef', 'hex'),
    address: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb1',
    nil: null,
    array: [1, 2, 3, 4, 5],
    nested: {
        a: 1,
        b: [true, false],
        c: 'nested string'
    }
};
const encoded3 = encode(types);
console.log('All types encoded (hex):', '0x' + encoded3.toString('hex'));
console.log('Size:', encoded3.length, 'bytes');
console.log('Decoded:', decode(encoded3));
console.log();

// Example 6: Array with mixed types
console.log('Example 6: Heterogeneous array');
const mixed = [42, 'hello', true, null, [1, 2, 3], { key: 'value' }];
const encoded4 = encode(mixed);
console.log('Mixed array:', mixed);
console.log('Encoded (hex):', '0x' + encoded4.toString('hex'));
console.log('Decoded:', decode(encoded4));
console.log();

// Example 7: Demonstrate type inspection during decoding
console.log('Example 7: Generic decoding with type inspection');
const decoder = new Decoder(encoded4);
console.log('Has more data:', decoder.hasMore());
console.log('Peek category:', decoder.peekCategory());
const arrayLen = decoder.decodeArrayLength();
console.log('Array length:', arrayLen);

for (let i = 0; i < arrayLen; i++) {
    const category = decoder.peekCategory();
    console.log(`  Item ${i} category:`, category);
    const value = decoder.decode();
    console.log(`  Item ${i} value:`, value);
}
console.log();

// Example 8: Skip functionality
console.log('Example 8: Selective decoding with skip');
const data = { a: 1, b: 'skip me', c: 3, d: [1, 2, 3], e: 5 };
const encoded5 = encode(data);
const dec = new Decoder(encoded5);
const mapLen = dec.decodeMapLength();
console.log('Map has', mapLen, 'entries');

for (let i = 0; i < mapLen; i++) {
    const key = dec.decodeString();
    if (key === 'a' || key === 'c' || key === 'e') {
        const value = dec.decodeUint();
        console.log(`  Decoded ${key}:`, value);
    } else {
        console.log(`  Skipped ${key}`);
        dec.skip();
    }
}
console.log();

console.log('=== All examples completed ===');
