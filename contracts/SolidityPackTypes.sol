// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title SolidityPackTypes
 * @notice Shared type constants and structs for SolidityPack encoding/decoding
 * @dev This library contains only constants and is optimized away at compile time
 */

library SolidityPackTypes {

    // Type constants
    uint8 internal constant FIXINT_POS_MAX = 0x7F;
    uint8 internal constant FIXMAP_BASE = 0x80;
    uint8 internal constant FIXARRAY_BASE = 0x90;
    uint8 internal constant FIXSTR_BASE = 0xA0;
    uint8 internal constant NIL = 0xC0;
    uint8 internal constant FALSE = 0xC2;
    uint8 internal constant TRUE = 0xC3;
    uint8 internal constant UINT8 = 0xC4;
    uint8 internal constant UINT16 = 0xC5;
    uint8 internal constant UINT32 = 0xC6;
    uint8 internal constant UINT64 = 0xC7;
    uint8 internal constant UINT128 = 0xC8;
    uint8 internal constant UINT256 = 0xC9;
    uint8 internal constant INT8 = 0xCA;
    uint8 internal constant INT16 = 0xCB;
    uint8 internal constant INT32 = 0xCC;
    uint8 internal constant INT64 = 0xCD;
    uint8 internal constant INT128 = 0xCE;
    uint8 internal constant INT256 = 0xCF;
    uint8 internal constant BYTES8 = 0xD0;
    uint8 internal constant BYTES16 = 0xD1;
    uint8 internal constant STR8 = 0xD2;
    uint8 internal constant STR16 = 0xD3;
    uint8 internal constant ADDRESS = 0xD4;
    uint8 internal constant BYTES32_TYPE = 0xD5;
    uint8 internal constant ARRAY8 = 0xD6;
    uint8 internal constant ARRAY16 = 0xD7;
    uint8 internal constant MAP8 = 0xD8;
    uint8 internal constant MAP16 = 0xD9;
    uint8 internal constant FIXINT_NEG_BASE = 0xE0;

    // Growth strategy constants for encoder
    uint256 internal constant INITIAL_BUFFER_SIZE = 256;
    uint256 internal constant GROWTH_THRESHOLD = 4096;
    uint256 internal constant MIN_GROWTH_MARGIN = 128;

    // Encoder struct
    struct Encoder {
        bytes buffer;
        uint256 pos;
    }

    // Decoder struct
    struct Decoder {
        bytes data;
        uint256 pos;
    }
}
