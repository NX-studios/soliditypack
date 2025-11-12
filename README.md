# SolidityPack

Gas-efficient, self-describing serialization format for Solidity with **modular encoder/decoder packages** to minimize smart contract bytecode size.

[![Tests](https://img.shields.io/badge/tests-46%20passing-brightgreen)]()
[![Solidity](https://img.shields.io/badge/solidity-^0.8.0-blue)]()
[![License](https://img.shields.io/badge/license-MIT-blue)]()

## Features

- **SPack API**: Ultra-concise encoding with short function names (`u()`, `s()`, `a()`) - 50% less code!
- **Modular Design**: Separate encoder and decoder libraries - only import what you need to save bytecode
- **Type-Safe**: Strongly typed encoding/decoding for all Solidity types
- **Generic Decoding**: Automatically detect and decode unknown data structures
- **Gas Optimized**: Hand-tuned assembly for efficient memory operations
- **Nested Support**: Encode/decode complex nested objects, arrays, and maps
- **MessagePack Compatible**: Basic types use standard MessagePack format
- **Ethereum Native**: Built-in support for `address`, `bytes32`, and `uint256`
- **Cross-Platform**: Works in both Solidity smart contracts and JavaScript/Node.js

## Installation

### JavaScript/Node.js

```bash
npm install soliditypack
```

The library has **zero runtime dependencies**! Import what you need:

```javascript
// Import everything
import { encode, decode, Encoder, Decoder } from 'soliditypack';

// Or import specific modules
import { Encoder, encodeToHex } from 'soliditypack/encoder';
import { Decoder, TypeCategory } from 'soliditypack/decoder';
import { decodeAll, decodePretty } from 'soliditypack/helpers';
```

### Solidity

First, install the package in your Solidity project:

```bash
npm install soliditypack
```

Then import only what you need to save bytecode:

```solidity
// For encoding only (recommended - concise SPack API)
import "soliditypack/contracts/SPack.sol";

// For decoding only
import "soliditypack/contracts/SolidityPackDecoder.sol";
import "soliditypack/contracts/SolidityPackTypes.sol";

// For both encoding and decoding
import "soliditypack/contracts/SPack.sol";
import "soliditypack/contracts/SolidityPackDecoder.sol";
import "soliditypack/contracts/SolidityPackTypes.sol";
```

## Quick Start

### JavaScript

#### Encode Data

```javascript
import { encode, encodeToHex } from 'soliditypack';

// Simple encoding
const data = { test: 42, test2: [] };
const encoded = encode(data);
console.log('0x' + encoded.toString('hex'));
// Output: 0x82a4746573742aa5746573743290

// Get hex directly
const hex = encodeToHex({ name: 'Alice', age: 30 });
console.log(hex);
// Output: 0x82a46e616d65a5416c696365a36167651e
```

#### Decode Data

```javascript
import { decode } from 'soliditypack';

const hex = '0x82a4746573742aa5746573743290';
const decoded = decode(hex);
console.log(decoded);
// Output: { test: 42, test2: [] }
```

### Solidity

#### Encode Data

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "soliditypack/contracts/SPack.sol";

contract MyContract {
    function encodeUserData() public pure returns (bytes memory) {
        SPack.Builder memory b = SPack.builder();
        SPack.map(b, 3);
        SPack.s(b, "name");
        SPack.s(b, "Alice");
        SPack.s(b, "balance");
        SPack.u(b, 1000000);
        SPack.s(b, "active");
        SPack.bool_(b, true);
        return SPack.done(b);
    }
}
```

#### Decode Data

```solidity
import "soliditypack/contracts/SolidityPackDecoder.sol";
import "soliditypack/contracts/SolidityPackTypes.sol";

contract MyContract {
    function decodeUserData(bytes memory data) public pure returns (
        string memory name,
        uint256 balance
    ) {
        SolidityPackTypes.Decoder memory dec = SolidityPackDecoder.newDecoder(data);

        uint256 mapLen = SolidityPackDecoder.decodeMapLength(dec);

        for (uint256 i = 0; i < mapLen; i++) {
            string memory key = SolidityPackDecoder.decodeString(dec);

            if (keccak256(bytes(key)) == keccak256("name")) {
                name = SolidityPackDecoder.decodeString(dec);
            } else if (keccak256(bytes(key)) == keccak256("balance")) {
                balance = SolidityPackDecoder.decodeUint(dec);
            } else {
                SolidityPackDecoder.skip(dec); // Skip unknown fields
            }
        }
    }
}
```

## Usage Examples

### Example 1: Encode Simple Object (JavaScript)

```javascript
import { encode, decode } from 'soliditypack';

const user = {
    name: 'Alice',
    age: 30,
    active: true,
    roles: ['admin', 'user']
};

const encoded = encode(user);
console.log('Size:', encoded.length, 'bytes');

const decoded = decode(encoded);
console.log('Decoded:', decoded);
// Output: { name: 'Alice', age: 30, active: true, roles: ['admin', 'user'] }
```

### Example 2: Encode Ethereum Transaction (JavaScript)

```javascript
const tx = {
    from: '0x742d35cC6634c0532925A3b844bc9E7595F0beB1',
    to: '0x1234567890123456789012345678901234567890',
    amount: 1500000000000000000n,  // 1.5 ETH as BigInt
    nonce: 42,
    confirmed: false
};

const encoded = encode(tx);
console.log('Hex:', '0x' + encoded.toString('hex'));

const decoded = decode(encoded);
console.log('From:', decoded.from);
console.log('Amount:', decoded.amount);  // Returns BigInt
```

### Example 3: Generic Decoding with Type Inspection (JavaScript)

```javascript
import { Decoder, TypeCategory } from 'soliditypack/decoder';

const dec = new Decoder(encodedData);

// Check type before decoding
const category = dec.peekCategory();

if (category === TypeCategory.MAP) {
    const mapLen = dec.decodeMapLength();
    // Handle map...
} else if (category === TypeCategory.ARRAY) {
    const arrayLen = dec.decodeArrayLength();
    // Handle array...
} else {
    // Auto-decode
    const value = dec.decode();
}
```

### Example 4: Encode in Solidity, Decode in JavaScript

**Solidity:**
```solidity
function getEncodedData() public pure returns (bytes memory) {
    SPack.Builder memory b = SPack.builder();
    SPack.map(b, 2);
    SPack.s(b, "test");
    SPack.u(b, 42);
    SPack.s(b, "test2");
    SPack.arr(b, 0);
    return SPack.done(b);
}
```

**JavaScript:**
```javascript
import { decode } from 'soliditypack';

// Get data from contract
const encodedData = await contract.getEncodedData();

// Decode it
const decoded = decode(encodedData);
console.log(decoded);
// Output: { test: 42, test2: [] }
```

### Example 5: Arrays (Solidity)

```solidity
function encodeArrays() public pure returns (bytes memory) {
    uint256[] memory numbers = new uint256[](3);
    numbers[0] = 10;
    numbers[1] = 20;
    numbers[2] = 30;

    address[] memory addrs = new address[](2);
    addrs[0] = 0x742d35cC6634c0532925A3b844bc9E7595F0beB1;
    addrs[1] = 0x1234567890123456789012345678901234567890;

    SPack.Builder memory b = SPack.builder();
    SPack.map(b, 2);
    SPack.s(b, "numbers");
    SPack.arr(b, numbers.length);
    for (uint256 i = 0; i < numbers.length; i++) {
        SPack.u(b, numbers[i]);
    }
    SPack.s(b, "addresses");
    SPack.arr(b, addrs.length);
    for (uint256 i = 0; i < addrs.length; i++) {
        SPack.a(b, addrs[i]);
    }
    return SPack.done(b);
}
```

### Example 6: Nested Objects (JavaScript)

```javascript
const complex = {
    user: {
        name: 'Alice',
        settings: {
            theme: 'dark',
            notifications: true
        }
    },
    data: [1, 2, 3]
};

const encoded = encode(complex);
const decoded = decode(encoded);
// Perfect round-trip! Handles arbitrary nesting.
```

## SPack: Concise Encoding API

SPack is the recommended encoding library with **ultra-concise function names** and a **builder pattern** for clean, readable code.

### Before vs After

**Old Verbose API (deprecated):**
```solidity
SolidityPackTypes.Encoder memory enc = SolidityPackEncoder.newEncoder();
SolidityPackEncoder.startObject(enc, 2);
SolidityPackEncoder.encodeKey(enc, "name");
SolidityPackEncoder.encodeString(enc, "Alice");
SolidityPackEncoder.encodeKey(enc, "balance");
SolidityPackEncoder.encodeUint(enc, 1000000);
return SolidityPackEncoder.getEncoded(enc);
```

**New SPack API (recommended):**
```solidity
SPack.Builder memory b = SPack.builder();
SPack.map(b, 2);
SPack.s(b, "name");
SPack.s(b, "Alice");
SPack.s(b, "balance");
SPack.u(b, 1000000);
return SPack.done(b);
```

**Result:** Same encoding, 50% less code, more readable!

### Concise Function Names

```solidity
import "soliditypack/contracts/SPack.sol";

SPack.Builder memory b = SPack.builder();

// Short, memorable function names
SPack.u(b, 42);              // encode uint
SPack.i(b, -10);             // encode int
SPack.s(b, "hello");         // encode string
SPack.a(b, address(0x...));  // encode address
SPack.b32(b, keccak256(...)) // encode bytes32
SPack.bool_(b, true);        // encode bool
SPack.arr(b, 3);             // start array
SPack.map(b, 2);             // start map/object

bytes memory result = SPack.done(b);
```

### Builder Pattern Example

Encode a transaction object:

```solidity
function encodeTransaction(
    address from,
    address to,
    uint256 amount,
    bytes32 txHash
) public pure returns (bytes memory) {
    SPack.Builder memory b = SPack.builder();
    SPack.map(b, 4);
    SPack.s(b, "from");
    SPack.a(b, from);
    SPack.s(b, "to");
    SPack.a(b, to);
    SPack.s(b, "amount");
    SPack.u(b, amount);
    SPack.s(b, "txHash");
    SPack.b32(b, txHash);
    return SPack.done(b);
}
```

### Available Functions

**Basic Types:**
```solidity
SPack.u(builder, uint256)      // Encode uint
SPack.i(builder, int256)       // Encode int
SPack.s(builder, string)       // Encode string
SPack.b(builder, bytes)        // Encode bytes
SPack.bool_(builder, bool)     // Encode bool
SPack.nil(builder)             // Encode nil/null
```

**Ethereum Types:**
```solidity
SPack.a(builder, address)      // Encode address
SPack.b32(builder, bytes32)    // Encode bytes32
```

**Containers:**
```solidity
SPack.arr(builder, length)     // Start array
SPack.map(builder, numPairs)   // Start map/object
```

**Lifecycle:**
```solidity
SPack.builder()                // Create new builder
SPack.done(builder)            // Finalize and get bytes
```

**Benefits:**
- ✅ **50% less code** than verbose API
- ✅ **Ultra-readable** with short, clear names
- ✅ **Zero gas overhead** - optimized assembly
- ✅ **Minimal bytecode** - short function names
- ✅ **Type-safe** - Solidity compiler checks

## API Reference

### JavaScript API

#### Encoder
```javascript
import { Encoder, encode, encodeToHex } from 'soliditypack/encoder';

// Quick encode
const bytes = encode(data);
const hex = encodeToHex(data);

// Manual encoding
const enc = new Encoder();
enc.startMap(2);
enc.encodeString('key');
enc.encodeUint(42);
// ... more encoding
const result = enc.getEncoded();
```

#### Decoder
```javascript
import { Decoder, decode } from 'soliditypack/decoder';
import { decodeAll } from 'soliditypack/helpers';

// Quick decode
const data = decode(bytes);

// Decode multiple sequential items
const items = decodeAll(bytes);

// Manual decoding
const dec = new Decoder(bytes);
while (dec.hasMore()) {
    const value = dec.decode();
}
```

#### Helper Functions
```javascript
import {
    decode,
    decodeAll,
    decodeWithType,
    decodePretty,
    decodeStats,
    extractField,
    roundTrip
} from 'soliditypack/helpers';
```

### Solidity API

#### SPack Encoder (Recommended)

**Builder Functions:**
```solidity
SPack.builder()                          // Create new builder
SPack.u(builder, uint256)                // Encode uint
SPack.i(builder, int256)                 // Encode int
SPack.s(builder, string)                 // Encode string
SPack.b(builder, bytes)                  // Encode bytes
SPack.bool_(builder, bool)               // Encode bool
SPack.a(builder, address)                // Encode address
SPack.b32(builder, bytes32)              // Encode bytes32
SPack.nil(builder)                       // Encode nil/null
SPack.arr(builder, length)               // Start array
SPack.map(builder, numPairs)             // Start map/object
SPack.done(builder)                      // Finalize to bytes
```

**Direct Encoding (for simple values):**
```solidity
SPack.encode(uint256)                    // Returns bytes
SPack.encode(int256)                     // Returns bytes
SPack.encode(bool)                       // Returns bytes
SPack.encode(address)                    // Returns bytes
SPack.encode(string memory)              // Returns bytes
SPack.encode(bytes memory)               // Returns bytes
```

**Array Helpers:**
```solidity
SPack.array(uint256[] memory)            // Encode uint array
SPack.array(address[] memory)            // Encode address array
SPack.array(string[] memory)             // Encode string array
```

**Legacy SolidityPackEncoder (Still Supported):**
```solidity
// Available for backward compatibility
SolidityPackEncoder.newEncoder()
SolidityPackEncoder.encodeUint(enc, value)
SolidityPackEncoder.encodeString(enc, value)
// ... see v1 docs for full API
```

#### Decoder Functions
```solidity
SolidityPackDecoder.newDecoder(data)
SolidityPackDecoder.decodeBool(dec)
SolidityPackDecoder.decodeUint(dec)
SolidityPackDecoder.decodeInt(dec)
SolidityPackDecoder.decodeString(dec)
SolidityPackDecoder.decodeAddress(dec)
SolidityPackDecoder.decodeBytes32(dec)
SolidityPackDecoder.decodeBytes(dec)
SolidityPackDecoder.decodeArrayLength(dec)
SolidityPackDecoder.decodeMapLength(dec)
SolidityPackDecoder.peekCategory(dec)
SolidityPackDecoder.hasMore(dec)
SolidityPackDecoder.skip(dec)
```

## Testing

### Run JavaScript Examples

```bash
npm run example              # All encoding/decoding examples
npm run example:decode       # General decode examples
npm run example:nested       # Nested structure examples
npm run example:msgpack      # MessagePack compatibility
npm run example:user         # Example: {test: 42, test2: []}
```

### Run Solidity Tests

```bash
npm test                     # Run all 46+ tests
npm run compile              # Compile contracts
```

**Test Results:**
```
✔ 46 passing tests
  - 8 encoder tests
  - 13 decoder tests
  - 7 nested structure tests
  - 7 sequential encoding tests
  - 11 improved API tests
```

## Documentation

- **[EXAMPLES.md](EXAMPLES.md)** - Comprehensive examples with both Solidity and JavaScript
- **[DECODE_GUIDE.md](DECODE_GUIDE.md)** - Complete guide to the decode() function
- **[NESTED_STRUCTURES.md](NESTED_STRUCTURES.md)** - How nested maps and arrays work
- **[MSGPACK_COMPATIBILITY.md](MSGPACK_COMPATIBILITY.md)** - MessagePack compatibility details

## Supported Types

### Primitive Types
- `bool` - Boolean (true/false)
- `uint8` to `uint256` - Unsigned integers
- `int8` to `int256` - Signed integers
- `string` - UTF-8 strings
- `bytes` - Dynamic byte arrays
- `null` - Nil/null values

### Ethereum Types
- `address` - 20-byte Ethereum addresses
- `bytes32` - 32-byte fixed arrays (hashes, etc.)

### Complex Types
- **Arrays** - Dynamic arrays of any type
- **Maps/Objects** - Key-value pairs with string keys
- **Nested Structures** - Arbitrary nesting of arrays and maps

## Bytecode Optimization

Import **only what you need**:

### SPack Encoder Only (Recommended)
```solidity
import "soliditypack/contracts/SPack.sol";
// Minimal bytecode - concise API with short function names
```

### Decoder Only
```solidity
import "soliditypack/contracts/SolidityPackDecoder.sol";
import "soliditypack/contracts/SolidityPackTypes.sol";
// Smaller bytecode when only decoding
```

### Both Encoding and Decoding
```solidity
import "soliditypack/contracts/SPack.sol";
import "soliditypack/contracts/SolidityPackDecoder.sol";
import "soliditypack/contracts/SolidityPackTypes.sol";
// Full functionality
```

**Why SPack is smaller:**
- Short function names: `u()`, `s()`, `a()` vs `encodeUint()`, `encodeString()`, `encodeAddress()`
- Builder pattern reduces code duplication
- Optimizer can inline more aggressively
- Less bytecode per call site

## MessagePack Compatibility

SolidityPack uses **MessagePack format** for basic types with **Ethereum extensions**:

### ✓ Compatible with MessagePack
- Integers (up to 64-bit)
- Strings, booleans, null
- Arrays and maps
- Can decode basic SolidityPack data with any MessagePack library

### ⚡ Ethereum Extensions
- `uint128`, `uint256` (large integers for Solidity)
- `address` (20-byte Ethereum addresses)
- `bytes32` (32-byte hashes)
- No floating-point support (Solidity doesn't have floats)

See [MSGPACK_COMPATIBILITY.md](MSGPACK_COMPATIBILITY.md) for details.

## Use Cases

- **Smart Contract Storage**: Efficiently encode complex data structures
- **Cross-Chain Communication**: Serialize data for chain-to-chain messaging
- **Event Logs**: Compact event data encoding
- **Off-Chain Data**: Bridge Solidity and JavaScript applications
- **API Responses**: Serialize contract data for web frontends
- **State Snapshots**: Compact state serialization

## How It Works

### Encoding
```
{test: 42, test2: []}

    ↓

0x82 a4 74657374 2a a5 7465737432 90

│    │  │        │  │  │          │
│    │  │        │  │  │          └─ Empty array (0 items)
│    │  │        │  │  └─ String "test2" (5 chars)
│    │  │        │  └─ Integer 42
│    │  │        └─ String "test" (4 chars)
│    │  └─ String length header
│    └─ Map with 2 entries
└─ FixMap header
```

### Decoding
The decoder:
1. Reads the type tag
2. Determines the data structure
3. Recursively decodes nested elements
4. Returns native JavaScript/Solidity types

## Performance

- **Compact**: More compact than JSON for typical data
- **Fast**: Hand-optimized assembly for critical paths
- **Gas Efficient**: Minimal gas usage in Solidity
- **No External Calls**: Pure functions, no SLOAD/SSTORE

## Contributing

Contributions welcome! Please check:
- Tests pass: `npm test`
- Examples work: `npm run example`
- Code compiles: `npm run compile`

## License

MIT License - see LICENSE file for details

## Quick Links

- **Install**: `npm install soliditypack`
- **Test Suite**: `npm test` - 46 passing tests
- **Run Examples**: `npm run example:user`
- **Compile**: `npm run compile`
- **Docs**: See `*.md` files for comprehensive guides
