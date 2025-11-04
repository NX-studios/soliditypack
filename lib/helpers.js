// SolidityPack Convenience Helpers
import { encode, encodeToHex, Encoder } from './encoder.js';
import { decode, Decoder, TypeCategory } from './decoder.js';

/**
 * Decode from hex string or Buffer
 */
export function decodeAny(data) {
    return decode(data);
}

/**
 * Decode and validate structure
 * @param {Buffer|string} data - Encoded data
 * @param {Object} schema - Expected structure validation
 */
export function decodeWithValidation(data, schema) {
    const decoded = decode(data);

    if (schema.type === 'object') {
        if (typeof decoded !== 'object' || Array.isArray(decoded)) {
            throw new Error(`Expected object, got ${typeof decoded}`);
        }
        if (schema.required) {
            for (const key of schema.required) {
                if (!(key in decoded)) {
                    throw new Error(`Missing required field: ${key}`);
                }
            }
        }
    } else if (schema.type === 'array') {
        if (!Array.isArray(decoded)) {
            throw new Error(`Expected array, got ${typeof decoded}`);
        }
        if (schema.minLength !== undefined && decoded.length < schema.minLength) {
            throw new Error(`Array too short: expected >= ${schema.minLength}, got ${decoded.length}`);
        }
    }

    return decoded;
}

/**
 * Decode all values from encoded data (handles sequential encoding)
 */
export function decodeAll(data) {
    const decoder = new Decoder(data);
    const results = [];

    while (decoder.hasMore()) {
        results.push(decoder.decode());
    }

    return results;
}

/**
 * Decode and extract specific field from a map
 */
export function extractField(data, fieldName) {
    const decoded = decode(data);

    if (typeof decoded !== 'object' || Array.isArray(decoded)) {
        throw new Error('Data is not a map/object');
    }

    return decoded[fieldName];
}

/**
 * Decode with type inspection - returns {value, type}
 */
export function decodeWithType(data) {
    const decoder = new Decoder(data);
    const type = decoder.peekCategory();
    const value = decoder.decode();

    return { value, type };
}

/**
 * Decode array of specific type
 */
export function decodeTypedArray(data, expectedType) {
    const decoded = decode(data);

    if (!Array.isArray(decoded)) {
        throw new Error('Not an array');
    }

    const decoder = new Decoder(data);
    decoder.decodeArrayLength();

    for (let i = 0; i < decoded.length; i++) {
        const cat = decoder.peekCategory();
        if (cat !== expectedType) {
            throw new Error(`Element ${i}: expected ${expectedType}, got ${cat}`);
        }
        decoder.skip();
    }

    return decoded;
}

/**
 * Pretty print decoded data
 */
export function decodePretty(data, indent = 2) {
    const decoded = decode(data);

    // Handle BigInt serialization
    return JSON.stringify(decoded, (key, value) => {
        if (typeof value === 'bigint') {
            return value.toString() + 'n';
        }
        return value;
    }, indent);
}

/**
 * Decode and get statistics about the data
 */
export function decodeStats(data) {
    const decoder = new Decoder(data);
    const stats = {
        totalBytes: data.length || Buffer.from(data.slice(2), 'hex').length,
        types: {},
        depth: 0,
        arrays: 0,
        maps: 0,
        primitives: 0
    };

    function analyze(dec, depth = 0) {
        if (depth > stats.depth) stats.depth = depth;

        const cat = dec.peekCategory();
        stats.types[cat] = (stats.types[cat] || 0) + 1;

        if (cat === TypeCategory.ARRAY) {
            stats.arrays++;
            const len = dec.decodeArrayLength();
            for (let i = 0; i < len; i++) {
                analyze(dec, depth + 1);
            }
        } else if (cat === TypeCategory.MAP) {
            stats.maps++;
            const len = dec.decodeMapLength();
            for (let i = 0; i < len; i++) {
                analyze(dec, depth + 1); // key
                analyze(dec, depth + 1); // value
            }
        } else {
            stats.primitives++;
            dec.skip();
        }
    }

    analyze(decoder);

    return stats;
}

/**
 * Round-trip encode/decode for testing
 */
export function roundTrip(data) {
    const encoded = encode(data);
    const decoded = decode(encoded);
    return {
        original: data,
        encoded: '0x' + encoded.toString('hex'),
        decoded,
        bytesSize: encoded.length,
        matches: JSON.stringify(data) === JSON.stringify(decoded)
    };
}

/**
 * Merge multiple encoded items into one array
 */
export function mergeEncoded(...encodedItems) {
    const encoder = new Encoder();
    encoder.startArray(encodedItems.length);

    for (const item of encodedItems) {
        const decoded = decode(item);
        encoder.encode(decoded);
    }

    return encoder.getEncoded();
}

// Re-export main functions for convenience
export { encode, encodeToHex, decode, Decoder, TypeCategory };
