// SolidityPack JavaScript Encoder
// Matches the Solidity implementation

const FIXINT_POS_MAX = 0x7F;
const FIXMAP_BASE = 0x80;
const FIXARRAY_BASE = 0x90;
const FIXSTR_BASE = 0xA0;
const NIL = 0xC0;
const FALSE = 0xC2;
const TRUE = 0xC3;
const UINT8 = 0xC4;
const UINT16 = 0xC5;
const UINT32 = 0xC6;
const UINT64 = 0xC7;
const UINT128 = 0xC8;
const UINT256 = 0xC9;
const INT8 = 0xCA;
const INT16 = 0xCB;
const INT32 = 0xCC;
const INT64 = 0xCD;
const INT128 = 0xCE;
const INT256 = 0xCF;
const BYTES8 = 0xD0;
const BYTES16 = 0xD1;
const STR8 = 0xD2;
const STR16 = 0xD3;
const ADDRESS = 0xD4;
const BYTES32_TYPE = 0xD5;
const ARRAY8 = 0xD6;
const ARRAY16 = 0xD7;
const MAP8 = 0xD8;
const MAP16 = 0xD9;
const FIXINT_NEG_BASE = 0xE0;

class Encoder {
    constructor() {
        this.buffer = Buffer.alloc(256);
        this.pos = 0;
    }

    _ensureCapacity(required) {
        const needed = this.pos + required;
        if (needed <= this.buffer.length) return;

        let newSize;
        const currentSize = this.buffer.length;

        if (currentSize < 4096) {
            newSize = Math.floor((currentSize * 3) / 2);
            if (newSize < needed) newSize = needed;
            newSize += 128;
        } else {
            const growth = needed - currentSize;
            const margin = Math.max(Math.floor(growth / 4), 128);
            newSize = needed + margin;
        }

        const newBuffer = Buffer.alloc(newSize);
        this.buffer.copy(newBuffer);
        this.buffer = newBuffer;
    }

    encodeBool(value) {
        this._ensureCapacity(1);
        this.buffer[this.pos++] = value ? TRUE : FALSE;
        return this;
    }

    encodeNil() {
        this._ensureCapacity(1);
        this.buffer[this.pos++] = NIL;
        return this;
    }

    encodeUint(value) {
        if (typeof value === 'bigint') {
            return this._encodeUintBigInt(value);
        }

        value = Math.floor(value);
        if (value < 0) throw new Error('Value must be non-negative');

        if (value <= FIXINT_POS_MAX) {
            this._ensureCapacity(1);
            this.buffer[this.pos++] = value;
        } else if (value <= 0xFF) {
            this._ensureCapacity(2);
            this.buffer[this.pos++] = UINT8;
            this.buffer[this.pos++] = value;
        } else if (value <= 0xFFFF) {
            this._ensureCapacity(3);
            this.buffer[this.pos++] = UINT16;
            this.buffer.writeUInt16BE(value, this.pos);
            this.pos += 2;
        } else if (value <= 0xFFFFFFFF) {
            this._ensureCapacity(5);
            this.buffer[this.pos++] = UINT32;
            this.buffer.writeUInt32BE(value, this.pos);
            this.pos += 4;
        } else {
            // Use BigInt for larger values
            return this._encodeUintBigInt(BigInt(value));
        }
        return this;
    }

    _encodeUintBigInt(value) {
        if (value < 0n) throw new Error('Value must be non-negative');

        if (value <= BigInt(FIXINT_POS_MAX)) {
            this._ensureCapacity(1);
            this.buffer[this.pos++] = Number(value);
        } else if (value <= 0xFFn) {
            this._ensureCapacity(2);
            this.buffer[this.pos++] = UINT8;
            this.buffer[this.pos++] = Number(value);
        } else if (value <= 0xFFFFn) {
            this._ensureCapacity(3);
            this.buffer[this.pos++] = UINT16;
            this.buffer.writeUInt16BE(Number(value), this.pos);
            this.pos += 2;
        } else if (value <= 0xFFFFFFFFn) {
            this._ensureCapacity(5);
            this.buffer[this.pos++] = UINT32;
            this.buffer.writeUInt32BE(Number(value), this.pos);
            this.pos += 4;
        } else if (value <= 0xFFFFFFFFFFFFFFFFn) {
            this._ensureCapacity(9);
            this.buffer[this.pos++] = UINT64;
            this.buffer.writeBigUInt64BE(value, this.pos);
            this.pos += 8;
        } else if (value <= (1n << 128n) - 1n) {
            this._ensureCapacity(17);
            this.buffer[this.pos++] = UINT128;
            this._writeBigUInt(value, 16);
        } else if (value <= (1n << 256n) - 1n) {
            this._ensureCapacity(33);
            this.buffer[this.pos++] = UINT256;
            this._writeBigUInt(value, 32);
        } else {
            throw new Error('Value too large for uint256');
        }
        return this;
    }

    _writeBigUInt(value, bytes) {
        for (let i = bytes - 1; i >= 0; i--) {
            this.buffer[this.pos + i] = Number(value & 0xFFn);
            value >>= 8n;
        }
        this.pos += bytes;
    }

    encodeInt(value) {
        if (typeof value === 'bigint') {
            return this._encodeIntBigInt(value);
        }

        value = Math.floor(value);

        if (value >= 0) {
            return this.encodeUint(value);
        }

        if (value >= -32) {
            this._ensureCapacity(1);
            this.buffer[this.pos++] = FIXINT_NEG_BASE + (value + 32);
        } else if (value >= -128) {
            this._ensureCapacity(2);
            this.buffer[this.pos++] = INT8;
            this.buffer.writeInt8(value, this.pos++);
        } else if (value >= -32768) {
            this._ensureCapacity(3);
            this.buffer[this.pos++] = INT16;
            this.buffer.writeInt16BE(value, this.pos);
            this.pos += 2;
        } else if (value >= -2147483648) {
            this._ensureCapacity(5);
            this.buffer[this.pos++] = INT32;
            this.buffer.writeInt32BE(value, this.pos);
            this.pos += 4;
        } else {
            return this._encodeIntBigInt(BigInt(value));
        }
        return this;
    }

    _encodeIntBigInt(value) {
        if (value >= 0n) {
            return this._encodeUintBigInt(value);
        }

        if (value >= -32n) {
            this._ensureCapacity(1);
            this.buffer[this.pos++] = FIXINT_NEG_BASE + Number(value + 32n);
        } else if (value >= -128n) {
            this._ensureCapacity(2);
            this.buffer[this.pos++] = INT8;
            this.buffer.writeInt8(Number(value), this.pos++);
        } else if (value >= -32768n) {
            this._ensureCapacity(3);
            this.buffer[this.pos++] = INT16;
            this.buffer.writeInt16BE(Number(value), this.pos);
            this.pos += 2;
        } else if (value >= -2147483648n) {
            this._ensureCapacity(5);
            this.buffer[this.pos++] = INT32;
            this.buffer.writeInt32BE(Number(value), this.pos);
            this.pos += 4;
        } else {
            this._ensureCapacity(33);
            this.buffer[this.pos++] = INT256;
            this._writeBigInt(value, 32);
        }
        return this;
    }

    _writeBigInt(value, bytes) {
        // Two's complement for negative numbers
        if (value < 0n) {
            value = (1n << BigInt(bytes * 8)) + value;
        }
        this._writeBigUInt(value, bytes);
    }

    encodeAddress(value) {
        // Remove 0x prefix if present
        if (typeof value === 'string') {
            value = value.toLowerCase().replace(/^0x/, '');
            if (value.length !== 40) throw new Error('Invalid address length');
            value = Buffer.from(value, 'hex');
        }
        if (value.length !== 20) throw new Error('Address must be 20 bytes');

        this._ensureCapacity(21);
        this.buffer[this.pos++] = ADDRESS;
        value.copy(this.buffer, this.pos);
        this.pos += 20;
        return this;
    }

    encodeBytes32(value) {
        if (typeof value === 'string') {
            value = value.replace(/^0x/, '');
            if (value.length !== 64) throw new Error('Invalid bytes32 length');
            value = Buffer.from(value, 'hex');
        }
        if (value.length !== 32) throw new Error('bytes32 must be 32 bytes');

        this._ensureCapacity(33);
        this.buffer[this.pos++] = BYTES32_TYPE;
        value.copy(this.buffer, this.pos);
        this.pos += 32;
        return this;
    }

    encodeBytes(value) {
        if (typeof value === 'string') {
            // Assume hex string
            value = value.replace(/^0x/, '');
            value = Buffer.from(value, 'hex');
        }

        const len = value.length;
        if (len <= 255) {
            this._ensureCapacity(len + 2);
            this.buffer[this.pos++] = BYTES8;
            this.buffer[this.pos++] = len;
        } else {
            this._ensureCapacity(len + 3);
            this.buffer[this.pos++] = BYTES16;
            this.buffer.writeUInt16BE(len, this.pos);
            this.pos += 2;
        }
        value.copy(this.buffer, this.pos);
        this.pos += len;
        return this;
    }

    encodeString(value) {
        const buf = Buffer.from(value, 'utf8');
        const len = buf.length;

        if (len <= 31) {
            this._ensureCapacity(len + 1);
            this.buffer[this.pos++] = FIXSTR_BASE + len;
        } else if (len <= 255) {
            this._ensureCapacity(len + 2);
            this.buffer[this.pos++] = STR8;
            this.buffer[this.pos++] = len;
        } else {
            this._ensureCapacity(len + 3);
            this.buffer[this.pos++] = STR16;
            this.buffer.writeUInt16BE(len, this.pos);
            this.pos += 2;
        }
        buf.copy(this.buffer, this.pos);
        this.pos += len;
        return this;
    }

    startArray(length) {
        if (length <= 15) {
            this._ensureCapacity(1);
            this.buffer[this.pos++] = FIXARRAY_BASE + length;
        } else if (length <= 255) {
            this._ensureCapacity(2);
            this.buffer[this.pos++] = ARRAY8;
            this.buffer[this.pos++] = length;
        } else {
            this._ensureCapacity(3);
            this.buffer[this.pos++] = ARRAY16;
            this.buffer.writeUInt16BE(length, this.pos);
            this.pos += 2;
        }
        return this;
    }

    encodeArray(array) {
        this.startArray(array.length);
        for (const item of array) {
            this.encode(item);
        }
        return this;
    }

    startMap(length) {
        if (length <= 15) {
            this._ensureCapacity(1);
            this.buffer[this.pos++] = FIXMAP_BASE + length;
        } else if (length <= 255) {
            this._ensureCapacity(2);
            this.buffer[this.pos++] = MAP8;
            this.buffer[this.pos++] = length;
        } else {
            this._ensureCapacity(3);
            this.buffer[this.pos++] = MAP16;
            this.buffer.writeUInt16BE(length, this.pos);
            this.pos += 2;
        }
        return this;
    }

    encodeMap(obj) {
        const keys = Object.keys(obj);
        this.startMap(keys.length);
        for (const key of keys) {
            this.encodeString(key);
            this.encode(obj[key]);
        }
        return this;
    }

    // Auto-detect type and encode
    encode(value) {
        if (value === null || value === undefined) {
            return this.encodeNil();
        } else if (typeof value === 'boolean') {
            return this.encodeBool(value);
        } else if (typeof value === 'number') {
            if (Number.isInteger(value)) {
                return value >= 0 ? this.encodeUint(value) : this.encodeInt(value);
            } else {
                throw new Error('Floats not supported, use integers only');
            }
        } else if (typeof value === 'bigint') {
            return value >= 0n ? this.encodeUint(value) : this.encodeInt(value);
        } else if (typeof value === 'string') {
            return this.encodeString(value);
        } else if (Buffer.isBuffer(value)) {
            return this.encodeBytes(value);
        } else if (Array.isArray(value)) {
            return this.encodeArray(value);
        } else if (typeof value === 'object') {
            return this.encodeMap(value);
        } else {
            throw new Error(`Unsupported type: ${typeof value}`);
        }
    }

    getEncoded() {
        return this.buffer.slice(0, this.pos);
    }

    toHex() {
        return '0x' + this.getEncoded().toString('hex');
    }
}

export function encode(value) {
    const encoder = new Encoder();
    encoder.encode(value);
    return encoder.getEncoded();
}

export function encodeToHex(value) {
    return '0x' + encode(value).toString('hex');
}

export { Encoder };
