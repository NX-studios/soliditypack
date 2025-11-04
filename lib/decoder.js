// SolidityPack JavaScript Decoder
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

const TypeCategory = {
    NIL: 'NIL',
    BOOL: 'BOOL',
    UINT: 'UINT',
    INT: 'INT',
    BYTES: 'BYTES',
    STRING: 'STRING',
    ARRAY: 'ARRAY',
    MAP: 'MAP',
    ADDRESS: 'ADDRESS',
    BYTES32: 'BYTES32'
};

class Decoder {
    constructor(data) {
        if (typeof data === 'string') {
            data = data.replace(/^0x/, '');
            data = Buffer.from(data, 'hex');
        }
        this.data = data;
        this.pos = 0;
    }

    hasMore() {
        return this.pos < this.data.length;
    }

    peekType() {
        if (this.pos >= this.data.length) throw new Error('EOF');
        return this.data[this.pos];
    }

    peekCategory() {
        const tag = this.peekType();

        if (tag === NIL) return TypeCategory.NIL;
        if (tag === TRUE || tag === FALSE) return TypeCategory.BOOL;
        if (tag <= FIXINT_POS_MAX ||
            tag === UINT8 || tag === UINT16 || tag === UINT32 ||
            tag === UINT64 || tag === UINT128 || tag === UINT256) {
            return TypeCategory.UINT;
        }
        if (tag >= FIXINT_NEG_BASE ||
            tag === INT8 || tag === INT16 || tag === INT32 ||
            tag === INT64 || tag === INT128 || tag === INT256) {
            return TypeCategory.INT;
        }
        if (tag === BYTES8 || tag === BYTES16) return TypeCategory.BYTES;
        if ((tag >= FIXSTR_BASE && tag < FIXSTR_BASE + 32) ||
            tag === STR8 || tag === STR16) {
            return TypeCategory.STRING;
        }
        if ((tag >= FIXARRAY_BASE && tag < FIXARRAY_BASE + 16) ||
            tag === ARRAY8 || tag === ARRAY16) {
            return TypeCategory.ARRAY;
        }
        if ((tag >= FIXMAP_BASE && tag < FIXMAP_BASE + 16) ||
            tag === MAP8 || tag === MAP16) {
            return TypeCategory.MAP;
        }
        if (tag === ADDRESS) return TypeCategory.ADDRESS;
        if (tag === BYTES32_TYPE) return TypeCategory.BYTES32;

        throw new Error(`Unknown type tag: 0x${tag.toString(16)}`);
    }

    isCategory(category) {
        if (!this.hasMore()) return false;
        return this.peekCategory() === category;
    }

    decodeBool() {
        const tag = this.peekType();
        this.pos++;
        if (tag === TRUE) return true;
        if (tag === FALSE) return false;
        throw new Error('Not a boolean');
    }

    decodeNil() {
        if (this.peekType() !== NIL) throw new Error('Not nil');
        this.pos++;
        return null;
    }

    decodeUint() {
        const tag = this.peekType();
        this.pos++;

        if (tag <= FIXINT_POS_MAX) {
            return tag;
        } else if (tag === UINT8) {
            return this.data[this.pos++];
        } else if (tag === UINT16) {
            const val = this.data.readUInt16BE(this.pos);
            this.pos += 2;
            return val;
        } else if (tag === UINT32) {
            const val = this.data.readUInt32BE(this.pos);
            this.pos += 4;
            return val;
        } else if (tag === UINT64) {
            const val = this.data.readBigUInt64BE(this.pos);
            this.pos += 8;
            return val;
        } else if (tag === UINT128) {
            const val = this._readBigUInt(16);
            return val;
        } else if (tag === UINT256) {
            const val = this._readBigUInt(32);
            return val;
        }

        throw new Error('Invalid uint tag');
    }

    _readBigUInt(bytes) {
        let val = 0n;
        for (let i = 0; i < bytes; i++) {
            val = (val << 8n) | BigInt(this.data[this.pos++]);
        }
        return val;
    }

    decodeInt() {
        const tag = this.peekType();

        if (tag <= FIXINT_POS_MAX) {
            this.pos++;
            return tag;
        } else if (tag >= FIXINT_NEG_BASE) {
            this.pos++;
            return tag - FIXINT_NEG_BASE - 32;
        }

        this.pos++;

        if (tag === INT8) {
            return this.data.readInt8(this.pos++);
        } else if (tag === INT16) {
            const val = this.data.readInt16BE(this.pos);
            this.pos += 2;
            return val;
        } else if (tag === INT32) {
            const val = this.data.readInt32BE(this.pos);
            this.pos += 4;
            return val;
        } else if (tag === INT256) {
            return this._readBigInt(32);
        }

        throw new Error('Invalid int tag');
    }

    _readBigInt(bytes) {
        let val = this._readBigUInt(bytes);
        // Check sign bit and convert from two's complement if negative
        const signBit = 1n << BigInt((bytes * 8) - 1);
        if (val >= signBit) {
            val = val - (1n << BigInt(bytes * 8));
        }
        return val;
    }

    decodeAddress() {
        if (this.peekType() !== ADDRESS) throw new Error('Not an address');
        this.pos++;
        const addr = this.data.slice(this.pos, this.pos + 20);
        this.pos += 20;
        return '0x' + addr.toString('hex');
    }

    decodeBytes32() {
        if (this.peekType() !== BYTES32_TYPE) throw new Error('Not bytes32');
        this.pos++;
        const bytes = this.data.slice(this.pos, this.pos + 32);
        this.pos += 32;
        return '0x' + bytes.toString('hex');
    }

    decodeBytes() {
        const tag = this.peekType();
        this.pos++;

        let len;
        if (tag === BYTES8) {
            len = this.data[this.pos++];
        } else if (tag === BYTES16) {
            len = this.data.readUInt16BE(this.pos);
            this.pos += 2;
        } else {
            throw new Error('Not bytes');
        }

        const bytes = this.data.slice(this.pos, this.pos + len);
        this.pos += len;
        return bytes;
    }

    decodeString() {
        const tag = this.peekType();
        this.pos++;

        let len;
        if (tag >= FIXSTR_BASE && tag < FIXSTR_BASE + 32) {
            len = tag - FIXSTR_BASE;
        } else if (tag === STR8) {
            len = this.data[this.pos++];
        } else if (tag === STR16) {
            len = this.data.readUInt16BE(this.pos);
            this.pos += 2;
        } else {
            throw new Error('Not string');
        }

        const str = this.data.slice(this.pos, this.pos + len).toString('utf8');
        this.pos += len;
        return str;
    }

    decodeArrayLength() {
        const tag = this.peekType();
        this.pos++;

        if (tag >= FIXARRAY_BASE && tag < FIXARRAY_BASE + 16) {
            return tag - FIXARRAY_BASE;
        } else if (tag === ARRAY8) {
            return this.data[this.pos++];
        } else if (tag === ARRAY16) {
            const len = this.data.readUInt16BE(this.pos);
            this.pos += 2;
            return len;
        }

        throw new Error('Not array');
    }

    decodeArray() {
        const len = this.decodeArrayLength();
        const arr = [];
        for (let i = 0; i < len; i++) {
            arr.push(this.decode());
        }
        return arr;
    }

    decodeMapLength() {
        const tag = this.peekType();
        this.pos++;

        if (tag >= FIXMAP_BASE && tag < FIXMAP_BASE + 16) {
            return tag - FIXMAP_BASE;
        } else if (tag === MAP8) {
            return this.data[this.pos++];
        } else if (tag === MAP16) {
            const len = this.data.readUInt16BE(this.pos);
            this.pos += 2;
            return len;
        }

        throw new Error('Not map');
    }

    decodeMap() {
        const len = this.decodeMapLength();
        const obj = {};
        for (let i = 0; i < len; i++) {
            const key = this.decodeString();
            const value = this.decode();
            obj[key] = value;
        }
        return obj;
    }

    // Auto-detect type and decode
    decode() {
        const category = this.peekCategory();

        switch (category) {
            case TypeCategory.NIL:
                return this.decodeNil();
            case TypeCategory.BOOL:
                return this.decodeBool();
            case TypeCategory.UINT:
                return this.decodeUint();
            case TypeCategory.INT:
                return this.decodeInt();
            case TypeCategory.BYTES:
                return this.decodeBytes();
            case TypeCategory.STRING:
                return this.decodeString();
            case TypeCategory.ARRAY:
                return this.decodeArray();
            case TypeCategory.MAP:
                return this.decodeMap();
            case TypeCategory.ADDRESS:
                return this.decodeAddress();
            case TypeCategory.BYTES32:
                return this.decodeBytes32();
            default:
                throw new Error(`Unknown category: ${category}`);
        }
    }

    skip() {
        const tag = this.peekType();
        this.pos++;

        if (tag <= FIXINT_POS_MAX || tag >= FIXINT_NEG_BASE) {
            return; // already consumed
        } else if (tag >= FIXSTR_BASE && tag < FIXSTR_BASE + 32) {
            this.pos += (tag - FIXSTR_BASE);
        } else if (tag >= FIXARRAY_BASE && tag < FIXARRAY_BASE + 16) {
            const len = tag - FIXARRAY_BASE;
            for (let i = 0; i < len; i++) this.skip();
        } else if (tag >= FIXMAP_BASE && tag < FIXMAP_BASE + 16) {
            const len = tag - FIXMAP_BASE;
            for (let i = 0; i < len * 2; i++) this.skip();
        } else if (tag === NIL || tag === TRUE || tag === FALSE) {
            return; // already consumed
        } else if (tag === UINT8 || tag === INT8) {
            this.pos += 1;
        } else if (tag === UINT16 || tag === INT16) {
            this.pos += 2;
        } else if (tag === UINT32 || tag === INT32) {
            this.pos += 4;
        } else if (tag === UINT64 || tag === INT64) {
            this.pos += 8;
        } else if (tag === UINT128 || tag === INT128) {
            this.pos += 16;
        } else if (tag === UINT256 || tag === INT256 || tag === BYTES32_TYPE) {
            this.pos += 32;
        } else if (tag === ADDRESS) {
            this.pos += 20;
        } else if (tag === BYTES8 || tag === STR8) {
            const len = this.data[this.pos++];
            this.pos += len;
        } else if (tag === BYTES16 || tag === STR16) {
            const len = this.data.readUInt16BE(this.pos);
            this.pos += 2 + len;
        } else if (tag === ARRAY8) {
            const len = this.data[this.pos++];
            for (let i = 0; i < len; i++) this.skip();
        } else if (tag === ARRAY16) {
            const len = this.data.readUInt16BE(this.pos);
            this.pos += 2;
            for (let i = 0; i < len; i++) this.skip();
        } else if (tag === MAP8) {
            const len = this.data[this.pos++];
            for (let i = 0; i < len * 2; i++) this.skip();
        } else if (tag === MAP16) {
            const len = this.data.readUInt16BE(this.pos);
            this.pos += 2;
            for (let i = 0; i < len * 2; i++) this.skip();
        } else {
            throw new Error(`Unknown type tag: 0x${tag.toString(16)}`);
        }
    }
}

export function decode(data) {
    const decoder = new Decoder(data);
    return decoder.decode();
}

export { Decoder, TypeCategory };
