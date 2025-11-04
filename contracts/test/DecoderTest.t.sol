// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../SolidityPackDecoder.sol";
import "../SolidityPackTypes.sol";

/**
 * @title DecoderTest
 * @notice Test contract demonstrating SolidityPack decoding
 */
contract DecoderTest {
    using SolidityPackDecoder for *;

    // Test decoding: {test: 42, test2: []}
    // Encoded as: 0x82a4746573742aa5746573743290
    function testDecodeMapWithEmptyArray() public pure returns (
        string memory key1,
        uint256 value1,
        string memory key2,
        uint256 arrayLen
    ) {
        bytes memory data = hex"82a4746573742aa5746573743290";
        SolidityPackTypes.Decoder memory dec = SolidityPackDecoder.newDecoder(data);

        uint256 mapLen = SolidityPackDecoder.decodeMapLength(dec);
        require(mapLen == 2, "Expected 2 map entries");

        key1 = SolidityPackDecoder.decodeString(dec);
        value1 = SolidityPackDecoder.decodeUint(dec);

        key2 = SolidityPackDecoder.decodeString(dec);
        arrayLen = SolidityPackDecoder.decodeArrayLength(dec);

        return (key1, value1, key2, arrayLen);
    }

    // Test generic type inspection
    function testTypeInspection() public pure returns (
        bool isMap,
        bool hasMoreAfterDecode
    ) {
        bytes memory data = hex"82a4746573742aa5746573743290";
        SolidityPackTypes.Decoder memory dec = SolidityPackDecoder.newDecoder(data);

        // Check if it's a map
        isMap = SolidityPackDecoder.isCategory(dec, SolidityPackDecoder.TypeCategory.MAP);

        // Decode it
        SolidityPackDecoder.decodeMapLength(dec);
        SolidityPackDecoder.skip(dec); // skip key1
        SolidityPackDecoder.skip(dec); // skip value1
        SolidityPackDecoder.skip(dec); // skip key2
        SolidityPackDecoder.skip(dec); // skip value2 (empty array)

        hasMoreAfterDecode = SolidityPackDecoder.hasMore(dec);

        return (isMap, hasMoreAfterDecode);
    }

    // Test decoding heterogeneous array
    function testDecodeHeterogeneousArray() public pure returns (
        uint256 uintVal,
        string memory strVal,
        bool boolVal,
        bool nilDecoded
    ) {
        // Encoded: [42, "hello", true, null]
        bytes memory data = hex"942aa568656c6c6fc3c0";
        SolidityPackTypes.Decoder memory dec = SolidityPackDecoder.newDecoder(data);

        uint256 len = SolidityPackDecoder.decodeArrayLength(dec);
        require(len == 4, "Expected 4 elements");

        uintVal = SolidityPackDecoder.decodeUint(dec);
        strVal = SolidityPackDecoder.decodeString(dec);
        boolVal = SolidityPackDecoder.decodeBool(dec);
        SolidityPackDecoder.decodeNil(dec);
        nilDecoded = true;

        return (uintVal, strVal, boolVal, nilDecoded);
    }

    // Test selective decoding with skip
    function testSelectiveDecoding() public pure returns (
        uint256 firstValue,
        uint256 thirdValue
    ) {
        // Map: {a: 1, b: 2, c: 3}
        bytes memory data = hex"83a16101a16202a16303";
        SolidityPackTypes.Decoder memory dec = SolidityPackDecoder.newDecoder(data);

        SolidityPackDecoder.decodeMapLength(dec);

        // Get first value
        SolidityPackDecoder.decodeString(dec); // key "a"
        firstValue = SolidityPackDecoder.decodeUint(dec); // value 1

        // Skip second entry
        SolidityPackDecoder.skip(dec); // key "b"
        SolidityPackDecoder.skip(dec); // value 2

        // Get third value
        SolidityPackDecoder.decodeString(dec); // key "c"
        thirdValue = SolidityPackDecoder.decodeUint(dec); // value 3

        return (firstValue, thirdValue);
    }

    // Test decoding address
    function testDecodeAddress() public pure returns (address addr) {
        // Encoded address: 0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb1
        bytes memory data = hex"d4742d35Cc6634C0532925a3b844Bc9e7595f0bEb1";
        SolidityPackTypes.Decoder memory dec = SolidityPackDecoder.newDecoder(data);

        addr = SolidityPackDecoder.decodeAddress(dec);
        return addr;
    }

    // Test decoding bytes32
    function testDecodeBytes32() public pure returns (bytes32 value) {
        // Encoded bytes32: 0x00000000000000000000000000000000000000000000000000000000deadbeef
        bytes memory data = hex"d500000000000000000000000000000000000000000000000000000000deadbeef";
        SolidityPackTypes.Decoder memory dec = SolidityPackDecoder.newDecoder(data);

        value = SolidityPackDecoder.decodeBytes32(dec);
        return value;
    }

    // Test decoding uint array helper
    function testDecodeUintArray() public pure returns (
        uint256 len,
        uint256 first,
        uint256 last
    ) {
        // Encoded: [10, 20, 30]
        bytes memory data = hex"930a141e";
        SolidityPackTypes.Decoder memory dec = SolidityPackDecoder.newDecoder(data);

        uint256[] memory arr = SolidityPackDecoder.decodeUintArray(dec);
        len = arr.length;
        first = arr[0];
        last = arr[arr.length - 1];

        return (len, first, last);
    }

    // Test decoding address array helper
    function testDecodeAddressArray() public pure returns (
        uint256 len,
        address first,
        address second
    ) {
        // Encoded: [0x1111..., 0x2222...]
        bytes memory data = hex"92d41111111111111111111111111111111111111111d42222222222222222222222222222222222222222";
        SolidityPackTypes.Decoder memory dec = SolidityPackDecoder.newDecoder(data);

        address[] memory arr = SolidityPackDecoder.decodeAddressArray(dec);
        len = arr.length;
        first = arr[0];
        second = arr[1];

        return (len, first, second);
    }

    // Test decoding string array helper
    function testDecodeStringArray() public pure returns (
        uint256 len,
        string memory first,
        string memory second
    ) {
        // Encoded: ["hello", "world"]
        bytes memory data = hex"92a568656c6c6fa5776f726c64";
        SolidityPackTypes.Decoder memory dec = SolidityPackDecoder.newDecoder(data);

        string[] memory arr = SolidityPackDecoder.decodeStringArray(dec);
        len = arr.length;
        first = arr[0];
        second = arr[1];

        return (len, first, second);
    }

    // Test decoding nested objects
    function testDecodeNestedObject() public pure returns (
        string memory name,
        uint256 age,
        uint256 tagsLen,
        string memory firstTag
    ) {
        // {name: "Alice", age: 30, tags: ["user", "active"]}
        bytes memory data = hex"83a46e616d65a5416c696365a36167651ea47461677392a475736572a6616374697665";
        SolidityPackTypes.Decoder memory dec = SolidityPackDecoder.newDecoder(data);

        uint256 mapLen = SolidityPackDecoder.decodeMapLength(dec);
        require(mapLen == 3, "Expected 3 fields");

        // name
        SolidityPackDecoder.decodeString(dec); // key
        name = SolidityPackDecoder.decodeString(dec);

        // age
        SolidityPackDecoder.decodeString(dec); // key
        age = SolidityPackDecoder.decodeUint(dec);

        // tags
        SolidityPackDecoder.decodeString(dec); // key
        string[] memory tags = SolidityPackDecoder.decodeStringArray(dec);
        tagsLen = tags.length;
        firstTag = tags[0];

        return (name, age, tagsLen, firstTag);
    }

    // Test peekCategory for different types
    function testPeekCategory() public pure returns (
        bool allCorrect
    ) {
        bytes memory data = hex"96c32aad48656c6c6fc0d41111111111111111111111111111111111111111d500000000000000000000000000000000000000000000000000000000deadbeef";
        // Array: [true, 42, "Hello", null, address, bytes32]
        SolidityPackTypes.Decoder memory dec = SolidityPackDecoder.newDecoder(data);

        SolidityPackDecoder.decodeArrayLength(dec);

        bool c1 = SolidityPackDecoder.peekCategory(dec) == SolidityPackDecoder.TypeCategory.BOOL;
        SolidityPackDecoder.skip(dec);

        bool c2 = SolidityPackDecoder.peekCategory(dec) == SolidityPackDecoder.TypeCategory.UINT;
        SolidityPackDecoder.skip(dec);

        bool c3 = SolidityPackDecoder.peekCategory(dec) == SolidityPackDecoder.TypeCategory.STRING;
        SolidityPackDecoder.skip(dec);

        bool c4 = SolidityPackDecoder.peekCategory(dec) == SolidityPackDecoder.TypeCategory.NIL;
        SolidityPackDecoder.skip(dec);

        bool c5 = SolidityPackDecoder.peekCategory(dec) == SolidityPackDecoder.TypeCategory.ADDRESS;
        SolidityPackDecoder.skip(dec);

        bool c6 = SolidityPackDecoder.peekCategory(dec) == SolidityPackDecoder.TypeCategory.BYTES32;
        SolidityPackDecoder.skip(dec);

        allCorrect = c1 && c2 && c3 && c4 && c5 && c6;
        return allCorrect;
    }

    // Test decoding large numbers
    function testDecodeLargeNumbers() public pure returns (
        uint256 val1,
        uint256 val2
    ) {
        // [type(uint64).max, type(uint128).max]
        bytes memory data = hex"92c7ffffffffffffffffc8ffffffffffffffffffffffffffffffffffffffff";
        SolidityPackTypes.Decoder memory dec = SolidityPackDecoder.newDecoder(data);

        SolidityPackDecoder.decodeArrayLength(dec);
        val1 = SolidityPackDecoder.decodeUint(dec);
        val2 = SolidityPackDecoder.decodeUint(dec);

        return (val1, val2);
    }

    // Test decoding negative numbers
    function testDecodeNegativeNumbers() public pure returns (
        int256 val1,
        int256 val2,
        int256 val3
    ) {
        // [-1, -128, type(int32).min]
        bytes memory data = hex"93ffca80cc80000000";
        SolidityPackTypes.Decoder memory dec = SolidityPackDecoder.newDecoder(data);

        SolidityPackDecoder.decodeArrayLength(dec);
        val1 = SolidityPackDecoder.decodeInt(dec);
        val2 = SolidityPackDecoder.decodeInt(dec);
        val3 = SolidityPackDecoder.decodeInt(dec);

        return (val1, val2, val3);
    }
}
