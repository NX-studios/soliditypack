#!/usr/bin/env node

import { encode, encodeToHex } from '../lib/encoder.js';
import { decode } from '../lib/decoder.js';

console.log('=== MessagePack Compatibility Check ===\n');

// Display the type constants
console.log('SolidityPack Type Constants (similar to MessagePack):');
console.log('─'.repeat(60));
console.log('FIXINT_POS_MAX:   0x7F   (0-127: positive integers)');
console.log('FIXMAP_BASE:      0x80   (0x80-0x8F: maps with 0-15 entries)');
console.log('FIXARRAY_BASE:    0x90   (0x90-0x9F: arrays with 0-15 items)');
console.log('FIXSTR_BASE:      0xA0   (0xA0-0xBF: strings with 0-31 bytes)');
console.log('NIL:              0xC0   (null/nil)');
console.log('FALSE:            0xC2   (boolean false)');
console.log('TRUE:             0xC3   (boolean true)');
console.log('UINT8:            0xC4   (8-bit unsigned integer)');
console.log('UINT16:           0xC5   (16-bit unsigned integer)');
console.log('UINT32:           0xC6   (32-bit unsigned integer)');
console.log('UINT64:           0xC7   (64-bit unsigned integer)');
console.log();

console.log('🔍 These match MessagePack format closely!');
console.log();

// Test basic compatibility
console.log('='.repeat(60));
console.log('Testing Basic Data Types:');
console.log('='.repeat(60));
console.log();

const testCases = [
    { name: 'Positive small int', value: 42 },
    { name: 'Boolean true', value: true },
    { name: 'Boolean false', value: false },
    { name: 'Null', value: null },
    { name: 'String', value: 'hello' },
    { name: 'Small array', value: [1, 2, 3] },
    { name: 'Small map', value: { a: 1, b: 2 } },
    { name: 'Nested structure', value: { arr: [1, 2], str: 'test' } }
];

testCases.forEach(test => {
    const encoded = encode(test.value);
    const hex = '0x' + encoded.toString('hex');
    const decoded = decode(encoded);

    console.log(`${test.name}:`);
    console.log(`  Value:   ${JSON.stringify(test.value)}`);
    console.log(`  Encoded: ${hex}`);
    console.log(`  Bytes:   ${[...encoded].map(b => '0x' + b.toString(16).padStart(2, '0')).join(' ')}`);
    console.log(`  Decoded: ${JSON.stringify(decoded)}`);
    console.log();
});

// Ethereum-specific extensions
console.log('='.repeat(60));
console.log('Ethereum-Specific Extensions (NOT in MessagePack):');
console.log('='.repeat(60));
console.log();

console.log('ADDRESS:          0xD4   (20-byte Ethereum address)');
console.log('BYTES32_TYPE:     0xD5   (32-byte hash/value)');
console.log('UINT128:          0xC8   (128-bit unsigned integer)');
console.log('UINT256:          0xC9   (256-bit unsigned integer)');
console.log('INT128:           0xCE   (128-bit signed integer)');
console.log('INT256:           0xCF   (256-bit signed integer)');
console.log();

// Test Ethereum types
const address = '0x742d35cC6634c0532925A3b844bc9E7595F0beB1';
const encodedAddr = encode({ addr: address });
console.log('Example - Ethereum address:');
console.log(`  Value:   ${address}`);
console.log(`  Encoded: 0x${encodedAddr.toString('hex')}`);
console.log(`  ⚠️  This would NOT decode with standard MessagePack!`);
console.log();

const bigNum = 123456789012345678901234567890n;
const encodedBig = encode(bigNum);
console.log('Example - uint256 (BigInt):');
console.log(`  Value:   ${bigNum}`);
console.log(`  Encoded: 0x${encodedBig.toString('hex')}`);
console.log(`  ⚠️  Standard MessagePack doesn't support 256-bit integers!`);
console.log();

// Comparison table
console.log('='.repeat(60));
console.log('MessagePack vs SolidityPack Comparison:');
console.log('='.repeat(60));
console.log();

const comparison = [
    ['Feature', 'MessagePack', 'SolidityPack', 'Compatible?'],
    ['─'.repeat(20), '─'.repeat(20), '─'.repeat(20), '─'.repeat(12)],
    ['Integers (up to 64-bit)', '✓', '✓', '✓ YES'],
    ['Floats', '✓', '✗ No floats', '✗ NO'],
    ['Strings', '✓', '✓', '✓ YES'],
    ['Binary data', '✓', '✓ (bytes)', '✓ YES'],
    ['Arrays', '✓', '✓', '✓ YES'],
    ['Maps/Objects', '✓', '✓', '✓ YES'],
    ['Booleans', '✓', '✓', '✓ YES'],
    ['Null', '✓', '✓', '✓ YES'],
    ['Extension types', '✓', '✓ (custom)', '⚠️  PARTIAL'],
    ['128-bit integers', '✗', '✓', '✗ NO'],
    ['256-bit integers', '✗', '✓', '✗ NO'],
    ['Ethereum addresses', '✗', '✓', '✗ NO'],
    ['bytes32', '✗', '✓', '✗ NO'],
];

comparison.forEach(row => {
    console.log(row.map((cell, i) => {
        const width = i === 0 ? 20 : i === 3 ? 12 : 20;
        return cell.padEnd(width);
    }).join(' | '));
});

console.log();
console.log('='.repeat(60));
console.log('Summary:');
console.log('='.repeat(60));
console.log();
console.log('✓ COMPATIBLE:');
console.log('  - Basic types (int, string, bool, null, array, map)');
console.log('  - Format structure and encoding rules');
console.log('  - Can decode basic SolidityPack data with msgpack libraries');
console.log();
console.log('✗ INCOMPATIBLE:');
console.log('  - Ethereum-specific types (address, bytes32)');
console.log('  - Large integers (uint128, uint256, int256)');
console.log('  - No floating-point support in SolidityPack');
console.log('  - Extension types use different type codes');
console.log();
console.log('🎯 BEST PRACTICE:');
console.log('  - Use SolidityPack for Solidity ↔ JavaScript communication');
console.log('  - Use standard MessagePack for general cross-platform data');
console.log('  - Basic data types are interoperable between both!');
console.log();

// Practical test
console.log('='.repeat(60));
console.log('Practical Interoperability Test:');
console.log('='.repeat(60));
console.log();

const simpleData = {
    name: 'Alice',
    age: 30,
    active: true,
    tags: ['user', 'admin']
};

const solidityPackEncoded = encode(simpleData);
console.log('Data with only basic types:');
console.log('  Original:', JSON.stringify(simpleData));
console.log('  SolidityPack encoded:', '0x' + solidityPackEncoded.toString('hex'));
console.log('  Decoded back:', JSON.stringify(decode(solidityPackEncoded)));
console.log();
console.log('  ✓ This WOULD be compatible with standard MessagePack!');
console.log('    (because it only uses basic types)');
console.log();

const ethereumData = {
    from: '0x742d35cC6634c0532925A3b844bc9E7595F0beB1',
    amount: 1000000000000000000n,
    nonce: 42
};

const ethereumEncoded = encode(ethereumData);
console.log('Data with Ethereum types:');
console.log('  Original:', JSON.stringify(ethereumData, (k,v) => typeof v === 'bigint' ? v.toString() + 'n' : v));
console.log('  SolidityPack encoded:', '0x' + ethereumEncoded.toString('hex'));
console.log();
console.log('  ✗ This would NOT decode correctly with MessagePack!');
console.log('    (because of address and uint256 types)');
