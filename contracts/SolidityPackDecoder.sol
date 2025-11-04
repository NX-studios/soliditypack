// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SolidityPackTypes.sol";

/**
 * @title SolidityPackDecoder
 * @notice Ultra gas-efficient decoding for SolidityPack format
 * @dev Decoder-only library to save bytecode in contracts that only decode
 */

library SolidityPackDecoder {
    using SolidityPackTypes for *;

    // ============ TYPE CATEGORIES ============

    enum TypeCategory {
        NIL,
        BOOL,
        UINT,
        INT,
        BYTES,
        STRING,
        ARRAY,
        MAP,
        ADDRESS,
        BYTES32
    }

    // ============ GENERIC TYPE INSPECTION ============

    /**
     * @notice Get the category of the next value without consuming it
     * @dev Useful for dynamic decoding when you don't know the type ahead of time
     */
    function peekCategory(SolidityPackTypes.Decoder memory dec) internal pure returns (TypeCategory) {
        require(dec.pos < dec.data.length, "EOF");
        uint8 tag = uint8(dec.data[dec.pos]);

        if (tag == SolidityPackTypes.NIL) {
            return TypeCategory.NIL;
        } else if (tag == SolidityPackTypes.TRUE || tag == SolidityPackTypes.FALSE) {
            return TypeCategory.BOOL;
        } else if (
            tag <= SolidityPackTypes.FIXINT_POS_MAX ||
            tag == SolidityPackTypes.UINT8 ||
            tag == SolidityPackTypes.UINT16 ||
            tag == SolidityPackTypes.UINT32 ||
            tag == SolidityPackTypes.UINT64 ||
            tag == SolidityPackTypes.UINT128 ||
            tag == SolidityPackTypes.UINT256
        ) {
            return TypeCategory.UINT;
        } else if (
            tag >= SolidityPackTypes.FIXINT_NEG_BASE ||
            tag == SolidityPackTypes.INT8 ||
            tag == SolidityPackTypes.INT16 ||
            tag == SolidityPackTypes.INT32 ||
            tag == SolidityPackTypes.INT64 ||
            tag == SolidityPackTypes.INT128 ||
            tag == SolidityPackTypes.INT256
        ) {
            return TypeCategory.INT;
        } else if (tag == SolidityPackTypes.BYTES8 || tag == SolidityPackTypes.BYTES16) {
            return TypeCategory.BYTES;
        } else if (
            (tag >= SolidityPackTypes.FIXSTR_BASE && tag < SolidityPackTypes.FIXSTR_BASE + 32) ||
            tag == SolidityPackTypes.STR8 ||
            tag == SolidityPackTypes.STR16
        ) {
            return TypeCategory.STRING;
        } else if (
            (tag >= SolidityPackTypes.FIXARRAY_BASE && tag < SolidityPackTypes.FIXARRAY_BASE + 16) ||
            tag == SolidityPackTypes.ARRAY8 ||
            tag == SolidityPackTypes.ARRAY16
        ) {
            return TypeCategory.ARRAY;
        } else if (
            (tag >= SolidityPackTypes.FIXMAP_BASE && tag < SolidityPackTypes.FIXMAP_BASE + 16) ||
            tag == SolidityPackTypes.MAP8 ||
            tag == SolidityPackTypes.MAP16
        ) {
            return TypeCategory.MAP;
        } else if (tag == SolidityPackTypes.ADDRESS) {
            return TypeCategory.ADDRESS;
        } else if (tag == SolidityPackTypes.BYTES32_TYPE) {
            return TypeCategory.BYTES32;
        }

        revert("Unknown type tag");
    }

    /**
     * @notice Check if the next value is of a specific category
     * @dev Useful for conditional decoding
     */
    function isCategory(
        SolidityPackTypes.Decoder memory dec,
        TypeCategory category
    ) internal pure returns (bool) {
        if (dec.pos >= dec.data.length) return false;
        return peekCategory(dec) == category;
    }

    /**
     * @notice Check if decoder has more data to read
     */
    function hasMore(SolidityPackTypes.Decoder memory dec) internal pure returns (bool) {
        return dec.pos < dec.data.length;
    }

    // ============ DECODER FUNCTIONS ============

    function newDecoder(bytes memory data) internal pure returns (SolidityPackTypes.Decoder memory) {
        return SolidityPackTypes.Decoder(data, 0);
    }

    function peekType(SolidityPackTypes.Decoder memory dec) internal pure returns (uint8) {
        require(dec.pos < dec.data.length, "EOF");
        return uint8(dec.data[dec.pos]);
    }

    function decodeBool(SolidityPackTypes.Decoder memory dec) internal pure returns (bool) {
        uint8 tag = peekType(dec);
        dec.pos++;
        require(tag == SolidityPackTypes.TRUE || tag == SolidityPackTypes.FALSE, "Not bool");
        return tag == SolidityPackTypes.TRUE;
    }

    function decodeNil(SolidityPackTypes.Decoder memory dec) internal pure {
        require(peekType(dec) == SolidityPackTypes.NIL, "Not nil");
        dec.pos++;
    }

    function decodeUint(SolidityPackTypes.Decoder memory dec) internal pure returns (uint256) {
        uint8 tag = peekType(dec);
        dec.pos++;

        if (tag <= SolidityPackTypes.FIXINT_POS_MAX) {
            return uint256(tag);
        } else if (tag == SolidityPackTypes.UINT8) {
            return uint256(uint8(dec.data[dec.pos++]));
        } else if (tag == SolidityPackTypes.UINT16) {
            uint256 val;
            assembly {
                let ptr := add(add(mload(dec), 32), mload(add(dec, 32)))
                val := or(shl(8, byte(0, mload(ptr))), byte(0, mload(add(ptr, 1))))
            }
            dec.pos += 2;
            return val;
        } else if (tag == SolidityPackTypes.UINT32) {
            uint256 val;
            assembly {
                let ptr := add(add(mload(dec), 32), mload(add(dec, 32)))
                val := or(
                    or(
                        or(shl(24, byte(0, mload(ptr))), shl(16, byte(0, mload(add(ptr, 1))))),
                        shl(8, byte(0, mload(add(ptr, 2))))
                    ),
                    byte(0, mload(add(ptr, 3)))
                )
            }
            dec.pos += 4;
            return val;
        } else if (tag == SolidityPackTypes.UINT64) {
            uint256 val;
            assembly {
                let ptr := add(add(mload(dec), 32), mload(add(dec, 32)))
                val := 0
                for { let i := 0 } lt(i, 8) { i := add(i, 1) } {
                    val := or(shl(8, val), byte(0, mload(add(ptr, i))))
                }
            }
            dec.pos += 8;
            return val;
        } else if (tag == SolidityPackTypes.UINT128) {
            uint256 val;
            assembly {
                let ptr := add(add(mload(dec), 32), mload(add(dec, 32)))
                val := 0
                for { let i := 0 } lt(i, 16) { i := add(i, 1) } {
                    val := or(shl(8, val), byte(0, mload(add(ptr, i))))
                }
            }
            dec.pos += 16;
            return val;
        } else if (tag == SolidityPackTypes.UINT256) {
            uint256 val;
            assembly {
                let ptr := add(add(mload(dec), 32), mload(add(dec, 32)))
                val := mload(ptr)
            }
            dec.pos += 32;
            return val;
        }

        revert("Invalid uint tag");
    }

    function decodeInt(SolidityPackTypes.Decoder memory dec) internal pure returns (int256) {
        uint8 tag = peekType(dec);

        if (tag <= SolidityPackTypes.FIXINT_POS_MAX) {
            dec.pos++;
            return int256(uint256(tag));
        } else if (tag >= SolidityPackTypes.FIXINT_NEG_BASE) {
            dec.pos++;
            return
                int8(uint8(tag)) -
                int8(uint8(SolidityPackTypes.FIXINT_NEG_BASE)) -
                32;
        }

        dec.pos++;

        if (tag == SolidityPackTypes.INT8) {
            return int8(uint8(dec.data[dec.pos++]));
        } else if (tag == SolidityPackTypes.INT16) {
            uint256 val;
            assembly {
                let ptr := add(add(mload(dec), 32), mload(add(dec, 32)))
                val := or(shl(8, byte(0, mload(ptr))), byte(0, mload(add(ptr, 1))))
                // Use signextend opcode
                val := signextend(1, val)
            }
            dec.pos += 2;
            return int256(val);
        } else if (tag == SolidityPackTypes.INT32) {
            uint256 val;
            assembly {
                let ptr := add(add(mload(dec), 32), mload(add(dec, 32)))
                val := or(
                    or(
                        or(shl(24, byte(0, mload(ptr))), shl(16, byte(0, mload(add(ptr, 1))))),
                        shl(8, byte(0, mload(add(ptr, 2))))
                    ),
                    byte(0, mload(add(ptr, 3)))
                )
                // Use signextend opcode
                val := signextend(3, val)
            }
            dec.pos += 4;
            return int256(val);
        } else if (tag == SolidityPackTypes.INT256) {
            int256 val;
            assembly {
                let ptr := add(add(mload(dec), 32), mload(add(dec, 32)))
                val := mload(ptr)
            }
            dec.pos += 32;
            return val;
        }

        revert("Invalid int tag");
    }

    function decodeAddress(
        SolidityPackTypes.Decoder memory dec
    ) internal pure returns (address) {
        require(peekType(dec) == SolidityPackTypes.ADDRESS, "Not address");
        dec.pos++;
        address val;
        assembly {
            let ptr := add(add(mload(dec), 32), mload(add(dec, 32)))
            val := shr(96, mload(ptr))
        }
        dec.pos += 20;
        return val;
    }

    function decodeBytes32(
        SolidityPackTypes.Decoder memory dec
    ) internal pure returns (bytes32) {
        require(peekType(dec) == SolidityPackTypes.BYTES32_TYPE, "Not bytes32");
        dec.pos++;
        bytes32 val;
        assembly {
            let ptr := add(add(mload(dec), 32), mload(add(dec, 32)))
            val := mload(ptr)
        }
        dec.pos += 32;
        return val;
    }

    function decodeBytes(
        SolidityPackTypes.Decoder memory dec
    ) internal pure returns (bytes memory) {
        uint8 tag = peekType(dec);
        dec.pos++;

        uint256 len;
        if (tag == SolidityPackTypes.BYTES8) {
            len = uint256(uint8(dec.data[dec.pos++]));
        } else if (tag == SolidityPackTypes.BYTES16) {
            len =
                (uint256(uint8(dec.data[dec.pos])) << 8) |
                uint256(uint8(dec.data[dec.pos + 1]));
            dec.pos += 2;
        } else {
            revert("Not bytes");
        }

        bytes memory result = new bytes(len);
        assembly {
            let src := add(add(mload(dec), 32), mload(add(dec, 32)))
            let dst := add(result, 32)

            // Copy full 32-byte chunks
            let fullChunks := div(len, 32)
            for { let i := 0 } lt(i, fullChunks) { i := add(i, 1) } {
                mstore(add(dst, mul(i, 32)), mload(add(src, mul(i, 32))))
            }

            // Copy remaining bytes if any
            let remaining := mod(len, 32)
            if gt(remaining, 0) {
                let lastChunkOffset := mul(fullChunks, 32)
                let mask := sub(shl(mul(remaining, 8), 1), 1)
                let srcData := and(
                    mload(add(src, lastChunkOffset)),
                    shl(sub(256, mul(remaining, 8)), mask)
                )
                mstore(add(dst, lastChunkOffset), srcData)
            }
        }
        dec.pos += len;
        return result;
    }

    function decodeString(
        SolidityPackTypes.Decoder memory dec
    ) internal pure returns (string memory) {
        uint8 tag = peekType(dec);
        dec.pos++;

        uint256 len;
        if (tag >= SolidityPackTypes.FIXSTR_BASE && tag < SolidityPackTypes.FIXSTR_BASE + 32) {
            len = uint256(tag - SolidityPackTypes.FIXSTR_BASE);
        } else if (tag == SolidityPackTypes.STR8) {
            len = uint256(uint8(dec.data[dec.pos++]));
        } else if (tag == SolidityPackTypes.STR16) {
            len =
                (uint256(uint8(dec.data[dec.pos])) << 8) |
                uint256(uint8(dec.data[dec.pos + 1]));
            dec.pos += 2;
        } else {
            revert("Not string");
        }

        bytes memory result = new bytes(len);
        assembly {
            let src := add(add(mload(dec), 32), mload(add(dec, 32)))
            let dst := add(result, 32)

            // Copy full 32-byte chunks
            let fullChunks := div(len, 32)
            for { let i := 0 } lt(i, fullChunks) { i := add(i, 1) } {
                mstore(add(dst, mul(i, 32)), mload(add(src, mul(i, 32))))
            }

            // Copy remaining bytes if any
            let remaining := mod(len, 32)
            if gt(remaining, 0) {
                let lastChunkOffset := mul(fullChunks, 32)
                let mask := sub(shl(mul(remaining, 8), 1), 1)
                let srcData := and(
                    mload(add(src, lastChunkOffset)),
                    shl(sub(256, mul(remaining, 8)), mask)
                )
                mstore(add(dst, lastChunkOffset), srcData)
            }
        }
        dec.pos += len;
        return string(result);
    }

    function decodeArrayLength(
        SolidityPackTypes.Decoder memory dec
    ) internal pure returns (uint256) {
        uint8 tag = peekType(dec);
        dec.pos++;

        if (tag >= SolidityPackTypes.FIXARRAY_BASE && tag < SolidityPackTypes.FIXARRAY_BASE + 16) {
            return uint256(tag - SolidityPackTypes.FIXARRAY_BASE);
        } else if (tag == SolidityPackTypes.ARRAY8) {
            return uint256(uint8(dec.data[dec.pos++]));
        } else if (tag == SolidityPackTypes.ARRAY16) {
            uint256 len = (uint256(uint8(dec.data[dec.pos])) << 8) |
                uint256(uint8(dec.data[dec.pos + 1]));
            dec.pos += 2;
            return len;
        }

        revert("Not array");
    }

    function decodeMapLength(
        SolidityPackTypes.Decoder memory dec
    ) internal pure returns (uint256) {
        uint8 tag = peekType(dec);
        dec.pos++;

        if (tag >= SolidityPackTypes.FIXMAP_BASE && tag < SolidityPackTypes.FIXMAP_BASE + 16) {
            return uint256(tag - SolidityPackTypes.FIXMAP_BASE);
        } else if (tag == SolidityPackTypes.MAP8) {
            return uint256(uint8(dec.data[dec.pos++]));
        } else if (tag == SolidityPackTypes.MAP16) {
            uint256 len = (uint256(uint8(dec.data[dec.pos])) << 8) |
                uint256(uint8(dec.data[dec.pos + 1]));
            dec.pos += 2;
            return len;
        }

        revert("Not map");
    }

    // ============ NESTED OBJECT DECODING ============

    /**
     * @notice Start decoding a nested object (map)
     * @return Number of key-value pairs
     */
    function decodeObjectLength(
        SolidityPackTypes.Decoder memory dec
    ) internal pure returns (uint256) {
        return decodeMapLength(dec);
    }

    /**
     * @notice Helper to decode array of uints
     */
    function decodeUintArray(
        SolidityPackTypes.Decoder memory dec
    ) internal pure returns (uint256[] memory) {
        uint256 len = decodeArrayLength(dec);
        uint256[] memory result = new uint256[](len);
        for (uint256 i = 0; i < len; i++) {
            result[i] = decodeUint(dec);
        }
        return result;
    }

    /**
     * @notice Helper to decode array of addresses
     */
    function decodeAddressArray(
        SolidityPackTypes.Decoder memory dec
    ) internal pure returns (address[] memory) {
        uint256 len = decodeArrayLength(dec);
        address[] memory result = new address[](len);
        for (uint256 i = 0; i < len; i++) {
            result[i] = decodeAddress(dec);
        }
        return result;
    }

    /**
     * @notice Helper to decode array of strings
     */
    function decodeStringArray(
        SolidityPackTypes.Decoder memory dec
    ) internal pure returns (string[] memory) {
        uint256 len = decodeArrayLength(dec);
        string[] memory result = new string[](len);
        for (uint256 i = 0; i < len; i++) {
            result[i] = decodeString(dec);
        }
        return result;
    }

    /**
     * @notice Skip the next value in the decoder (useful for unknown fields)
     */
    function skip(SolidityPackTypes.Decoder memory dec) internal pure {
        uint8 tag = peekType(dec);
        dec.pos++;

        // Handle different type categories
        if (tag <= SolidityPackTypes.FIXINT_POS_MAX || tag >= SolidityPackTypes.FIXINT_NEG_BASE) {
            // Fixint, already consumed
            return;
        } else if (
            tag >= SolidityPackTypes.FIXSTR_BASE && tag < SolidityPackTypes.FIXSTR_BASE + 32
        ) {
            // Fixstr
            dec.pos += (tag - SolidityPackTypes.FIXSTR_BASE);
        } else if (
            tag >= SolidityPackTypes.FIXARRAY_BASE && tag < SolidityPackTypes.FIXARRAY_BASE + 16
        ) {
            // Fixarray
            uint256 len = tag - SolidityPackTypes.FIXARRAY_BASE;
            for (uint256 i = 0; i < len; i++) {
                skip(dec);
            }
        } else if (
            tag >= SolidityPackTypes.FIXMAP_BASE && tag < SolidityPackTypes.FIXMAP_BASE + 16
        ) {
            // Fixmap
            uint256 len = tag - SolidityPackTypes.FIXMAP_BASE;
            for (uint256 i = 0; i < len * 2; i++) {
                skip(dec);
            }
        } else if (
            tag == SolidityPackTypes.NIL ||
            tag == SolidityPackTypes.TRUE ||
            tag == SolidityPackTypes.FALSE
        ) {
            // Already consumed
        } else if (tag == SolidityPackTypes.UINT8 || tag == SolidityPackTypes.INT8) {
            dec.pos += 1;
        } else if (tag == SolidityPackTypes.UINT16 || tag == SolidityPackTypes.INT16) {
            dec.pos += 2;
        } else if (tag == SolidityPackTypes.UINT32 || tag == SolidityPackTypes.INT32) {
            dec.pos += 4;
        } else if (tag == SolidityPackTypes.UINT64 || tag == SolidityPackTypes.INT64) {
            dec.pos += 8;
        } else if (tag == SolidityPackTypes.UINT128 || tag == SolidityPackTypes.INT128) {
            dec.pos += 16;
        } else if (
            tag == SolidityPackTypes.UINT256 ||
            tag == SolidityPackTypes.INT256 ||
            tag == SolidityPackTypes.BYTES32_TYPE
        ) {
            dec.pos += 32;
        } else if (tag == SolidityPackTypes.ADDRESS) {
            dec.pos += 20;
        } else if (tag == SolidityPackTypes.BYTES8 || tag == SolidityPackTypes.STR8) {
            uint256 len = uint256(uint8(dec.data[dec.pos++]));
            dec.pos += len;
        } else if (tag == SolidityPackTypes.BYTES16 || tag == SolidityPackTypes.STR16) {
            uint256 len = (uint256(uint8(dec.data[dec.pos])) << 8) |
                uint256(uint8(dec.data[dec.pos + 1]));
            dec.pos += 2 + len;
        } else if (tag == SolidityPackTypes.ARRAY8) {
            uint256 len = uint256(uint8(dec.data[dec.pos++]));
            for (uint256 i = 0; i < len; i++) {
                skip(dec);
            }
        } else if (tag == SolidityPackTypes.ARRAY16) {
            uint256 len = (uint256(uint8(dec.data[dec.pos])) << 8) |
                uint256(uint8(dec.data[dec.pos + 1]));
            dec.pos += 2;
            for (uint256 i = 0; i < len; i++) {
                skip(dec);
            }
        } else if (tag == SolidityPackTypes.MAP8) {
            uint256 len = uint256(uint8(dec.data[dec.pos++]));
            for (uint256 i = 0; i < len * 2; i++) {
                skip(dec);
            }
        } else if (tag == SolidityPackTypes.MAP16) {
            uint256 len = (uint256(uint8(dec.data[dec.pos])) << 8) |
                uint256(uint8(dec.data[dec.pos + 1]));
            dec.pos += 2;
            for (uint256 i = 0; i < len * 2; i++) {
                skip(dec);
            }
        } else {
            revert("Unknown type tag");
        }
    }
}
