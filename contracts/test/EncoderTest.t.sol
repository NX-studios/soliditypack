// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../SPack.sol";
import "../SolidityPackDecoder.sol";
import "../SolidityPackTypes.sol";

/**
 * @title EncoderTest
 * @notice Test contract demonstrating SPack encoding
 */
contract EncoderTest {
    using SPack for *;
    using SolidityPackDecoder for *;

    // Test encoding: {test: 42, test2: []}
    function testEncodeMapWithEmptyArray() public pure returns (bytes memory) {
        SPack.Builder memory b = SPack.builder();
        SPack.map(b, 2);
        SPack.s(b, "test");
        SPack.u(b, 42);
        SPack.s(b, "test2");
        SPack.arr(b, 0);
        return SPack.done(b);
    }

    // Test basic types
    function testEncodeBasicTypes() public pure returns (bytes memory) {
        SPack.Builder memory b = SPack.builder();
        SPack.arr(b, 7);
        SPack.bool_(b, true);
        SPack.u(b, 42);
        SPack.i(b, -100);
        SPack.s(b, "hello");
        SPack.a(b, address(0x742d35cC6634c0532925A3b844bc9E7595F0beB1));
        SPack.b32(b, bytes32(uint256(0xdeadbeef)));
        SPack.nil(b);
        return SPack.done(b);
    }

    // Test nested structures
    function testEncodeNestedStructure() public pure returns (bytes memory) {
        // Create: {name: "Alice", age: 30, tags: ["user", "active"]}
        SPack.Builder memory b = SPack.builder();
        SPack.map(b, 3);
        SPack.s(b, "name");
        SPack.s(b, "Alice");
        SPack.s(b, "age");
        SPack.u(b, 30);
        SPack.s(b, "tags");
        SPack.arr(b, 2);
        SPack.s(b, "user");
        SPack.s(b, "active");
        return SPack.done(b);
    }

    // Test array helpers
    function testEncodeArrayHelpers() public pure returns (bytes memory) {
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

        SPack.Builder memory b = SPack.builder();
        SPack.map(b, 3);
        SPack.s(b, "numbers");
        SPack.arr(b, numbers.length);
        for (uint256 i = 0; i < numbers.length; i++) {
            SPack.u(b, numbers[i]);
        }
        SPack.s(b, "addresses");
        SPack.arr(b, addresses.length);
        for (uint256 i = 0; i < addresses.length; i++) {
            SPack.a(b, addresses[i]);
        }
        SPack.s(b, "strings");
        SPack.arr(b, strings.length);
        for (uint256 i = 0; i < strings.length; i++) {
            SPack.s(b, strings[i]);
        }
        return SPack.done(b);
    }

    // Test large numbers
    function testEncodeLargeNumbers() public pure returns (bytes memory) {
        SPack.Builder memory b = SPack.builder();
        SPack.arr(b, 4);
        SPack.u(b, type(uint8).max);
        SPack.u(b, type(uint32).max);
        SPack.u(b, type(uint64).max);
        SPack.u(b, type(uint256).max);
        return SPack.done(b);
    }

    // Test negative numbers
    function testEncodeNegativeNumbers() public pure returns (bytes memory) {
        SPack.Builder memory b = SPack.builder();
        SPack.arr(b, 5);
        SPack.i(b, -1);
        SPack.i(b, -32);
        SPack.i(b, -128);
        SPack.i(b, type(int32).min);
        SPack.i(b, type(int256).min);
        return SPack.done(b);
    }

    // Test encoding and immediate decoding
    function testRoundTrip() public pure returns (
        bool success,
        uint256 decodedNumber,
        string memory decodedString
    ) {
        // Encode
        SPack.Builder memory b = SPack.builder();
        SPack.map(b, 2);
        SPack.s(b, "num");
        SPack.u(b, 12345);
        SPack.s(b, "str");
        SPack.s(b, "test string");
        bytes memory encoded = SPack.done(b);

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
        // {
        //   owner: address,
        //   balance: uint256,
        //   active: bool,
        //   metadata: {
        //     name: string,
        //     tags: [string, string]
        //   }
        // }

        SPack.Builder memory b = SPack.builder();
        SPack.map(b, 4);
        SPack.s(b, "owner");
        SPack.a(b, address(0x742d35cC6634c0532925A3b844bc9E7595F0beB1));
        SPack.s(b, "balance");
        SPack.u(b, 1000000);
        SPack.s(b, "active");
        SPack.bool_(b, true);
        SPack.s(b, "metadata");
        SPack.map(b, 2);
        SPack.s(b, "name");
        SPack.s(b, "Alice");
        SPack.s(b, "tags");
        SPack.arr(b, 2);
        SPack.s(b, "premium");
        SPack.s(b, "verified");
        return SPack.done(b);
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
