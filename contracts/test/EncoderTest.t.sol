// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../SolidityPackEncoder.sol";
import "../SolidityPackDecoder.sol";
import "../SolidityPackTypes.sol";

/**
 * @title EncoderTest
 * @notice Test contract demonstrating SolidityPack encoding
 */
contract EncoderTest {
    using SolidityPackEncoder for *;
    using SolidityPackDecoder for *;

    // Test encoding: {test: 42, test2: []}
    function testEncodeMapWithEmptyArray() public pure returns (bytes memory) {
        SolidityPackTypes.Encoder memory enc = SolidityPackEncoder.newEncoder();

        // Start map with 2 entries
        SolidityPackEncoder.startObject(enc, 2);

        // Entry 1: "test" => 42
        SolidityPackEncoder.encodeKey(enc, "test");
        SolidityPackEncoder.encodeUint(enc, 42);

        // Entry 2: "test2" => []
        SolidityPackEncoder.encodeKey(enc, "test2");
        SolidityPackEncoder.startArray(enc, 0);

        return SolidityPackEncoder.getEncoded(enc);
    }

    // Test basic types
    function testEncodeBasicTypes() public pure returns (bytes memory) {
        SolidityPackTypes.Encoder memory enc = SolidityPackEncoder.newEncoder();

        SolidityPackEncoder.startArray(enc, 7);
        SolidityPackEncoder.encodeBool(enc, true);
        SolidityPackEncoder.encodeUint(enc, 42);
        SolidityPackEncoder.encodeInt(enc, -100);
        SolidityPackEncoder.encodeString(enc, "hello");
        SolidityPackEncoder.encodeAddress(enc, address(0x742d35cC6634c0532925A3b844bc9E7595F0beB1));
        SolidityPackEncoder.encodeBytes32(enc, bytes32(uint256(0xdeadbeef)));
        SolidityPackEncoder.encodeNil(enc);

        return SolidityPackEncoder.getEncoded(enc);
    }

    // Test nested structures
    function testEncodeNestedStructure() public pure returns (bytes memory) {
        SolidityPackTypes.Encoder memory enc = SolidityPackEncoder.newEncoder();

        // Create: {name: "Alice", age: 30, tags: ["user", "active"]}
        SolidityPackEncoder.startObject(enc, 3);

        SolidityPackEncoder.encodeKey(enc, "name");
        SolidityPackEncoder.encodeString(enc, "Alice");

        SolidityPackEncoder.encodeKey(enc, "age");
        SolidityPackEncoder.encodeUint(enc, 30);

        SolidityPackEncoder.encodeKey(enc, "tags");
        SolidityPackEncoder.startArray(enc, 2);
        SolidityPackEncoder.encodeString(enc, "user");
        SolidityPackEncoder.encodeString(enc, "active");

        return SolidityPackEncoder.getEncoded(enc);
    }

    // Test array helpers
    function testEncodeArrayHelpers() public pure returns (bytes memory) {
        SolidityPackTypes.Encoder memory enc = SolidityPackEncoder.newEncoder();

        uint256[] memory numbers = new uint256[](3);
        numbers[0] = 10;
        numbers[1] = 20;
        numbers[2] = 30;

        address[] memory addresses = new address[](2);
        addresses[0] = address(0x1111111111111111111111111111111111111111);
        addresses[1] = address(0x2222222222222222222222222222222222222222);

        string[] memory strings = new string[](2);
        strings[0] = "hello";
        strings[1] = "world";

        SolidityPackEncoder.startObject(enc, 3);

        SolidityPackEncoder.encodeKey(enc, "numbers");
        SolidityPackEncoder.encodeUintArray(enc, numbers);

        SolidityPackEncoder.encodeKey(enc, "addresses");
        SolidityPackEncoder.encodeAddressArray(enc, addresses);

        SolidityPackEncoder.encodeKey(enc, "strings");
        SolidityPackEncoder.encodeStringArray(enc, strings);

        return SolidityPackEncoder.getEncoded(enc);
    }

    // Test large numbers
    function testEncodeLargeNumbers() public pure returns (bytes memory) {
        SolidityPackTypes.Encoder memory enc = SolidityPackEncoder.newEncoder();

        SolidityPackEncoder.startArray(enc, 4);
        SolidityPackEncoder.encodeUint(enc, type(uint8).max);
        SolidityPackEncoder.encodeUint(enc, type(uint32).max);
        SolidityPackEncoder.encodeUint(enc, type(uint64).max);
        SolidityPackEncoder.encodeUint(enc, type(uint256).max);

        return SolidityPackEncoder.getEncoded(enc);
    }

    // Test negative numbers
    function testEncodeNegativeNumbers() public pure returns (bytes memory) {
        SolidityPackTypes.Encoder memory enc = SolidityPackEncoder.newEncoder();

        SolidityPackEncoder.startArray(enc, 5);
        SolidityPackEncoder.encodeInt(enc, -1);
        SolidityPackEncoder.encodeInt(enc, -32);
        SolidityPackEncoder.encodeInt(enc, -128);
        SolidityPackEncoder.encodeInt(enc, type(int32).min);
        SolidityPackEncoder.encodeInt(enc, type(int256).min);

        return SolidityPackEncoder.getEncoded(enc);
    }

    // Test encoding and immediate decoding
    function testRoundTrip() public pure returns (
        bool success,
        uint256 decodedNumber,
        string memory decodedString
    ) {
        // Encode
        SolidityPackTypes.Encoder memory enc = SolidityPackEncoder.newEncoder();
        SolidityPackEncoder.startObject(enc, 2);
        SolidityPackEncoder.encodeKey(enc, "num");
        SolidityPackEncoder.encodeUint(enc, 12345);
        SolidityPackEncoder.encodeKey(enc, "str");
        SolidityPackEncoder.encodeString(enc, "test string");

        bytes memory encoded = SolidityPackEncoder.getEncoded(enc);

        // Decode
        SolidityPackTypes.Decoder memory dec = SolidityPackDecoder.newDecoder(encoded);
        uint256 mapLen = SolidityPackDecoder.decodeMapLength(dec);

        if (mapLen != 2) return (false, 0, "");

        // Decode first key-value pair
        string memory key1 = SolidityPackDecoder.decodeString(dec);
        uint256 value1 = SolidityPackDecoder.decodeUint(dec);

        // Decode second key-value pair
        string memory key2 = SolidityPackDecoder.decodeString(dec);
        string memory value2 = SolidityPackDecoder.decodeString(dec);

        bool keysMatch = keccak256(bytes(key1)) == keccak256(bytes("num")) &&
            keccak256(bytes(key2)) == keccak256(bytes("str"));

        return (keysMatch && value1 == 12345, value1, value2);
    }

    // Test complex nested object
    function testEncodeComplexObject() public pure returns (bytes memory) {
        SolidityPackTypes.Encoder memory enc = SolidityPackEncoder.newEncoder();

        // {
        //   owner: address,
        //   balance: uint256,
        //   active: bool,
        //   metadata: {
        //     name: string,
        //     tags: [string, string]
        //   }
        // }

        SolidityPackEncoder.startObject(enc, 4);

        SolidityPackEncoder.encodeKey(enc, "owner");
        SolidityPackEncoder.encodeAddress(enc, address(0x742d35cC6634c0532925A3b844bc9E7595F0beB1));

        SolidityPackEncoder.encodeKey(enc, "balance");
        SolidityPackEncoder.encodeUint(enc, 1000000);

        SolidityPackEncoder.encodeKey(enc, "active");
        SolidityPackEncoder.encodeBool(enc, true);

        SolidityPackEncoder.encodeKey(enc, "metadata");
        SolidityPackEncoder.startObject(enc, 2);
        SolidityPackEncoder.encodeKey(enc, "name");
        SolidityPackEncoder.encodeString(enc, "Alice");
        SolidityPackEncoder.encodeKey(enc, "tags");
        SolidityPackEncoder.startArray(enc, 2);
        SolidityPackEncoder.encodeString(enc, "premium");
        SolidityPackEncoder.encodeString(enc, "verified");

        return SolidityPackEncoder.getEncoded(enc);
    }

    // Helper to compare with JavaScript encoding
    function getExpectedEncoding() public pure returns (bytes memory) {
        // Expected encoding for {test: 42, test2: []}
        // 0x82a4746573742aa5746573743290
        return hex"82a4746573742aa5746573743290";
    }

    function verifyEncodingMatches() public pure returns (bool) {
        bytes memory encoded = testEncodeMapWithEmptyArray();
        bytes memory expected = getExpectedEncoding();

        if (encoded.length != expected.length) return false;

        for (uint256 i = 0; i < encoded.length; i++) {
            if (encoded[i] != expected[i]) return false;
        }

        return true;
    }
}
