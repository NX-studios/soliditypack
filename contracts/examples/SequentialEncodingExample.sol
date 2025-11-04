// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../SolidityPackEncoder.sol";
import "../SolidityPackDecoder.sol";
import "../SolidityPackTypes.sol";

/**
 * @title SequentialEncodingExample
 * @notice Demonstrates what happens when you encode data after a map
 */
contract SequentialEncodingExample {
    using SolidityPackEncoder for *;
    using SolidityPackDecoder for *;

    // Example 1: Map with 2 entries, then more data after
    function encodeMapThenMoreData() public pure returns (bytes memory) {
        SolidityPackTypes.Encoder memory enc = SolidityPackEncoder.newEncoder();

        // Encode a map with 2 entries
        SolidityPackEncoder.startMap(enc, 2);
        SolidityPackEncoder.encodeString(enc, "a");
        SolidityPackEncoder.encodeUint(enc, 1);
        SolidityPackEncoder.encodeString(enc, "b");
        SolidityPackEncoder.encodeUint(enc, 2);
        // Map is now complete (2 entries encoded)

        // Now encode MORE items AFTER the map
        SolidityPackEncoder.encodeUint(enc, 42);
        SolidityPackEncoder.encodeString(enc, "hello");

        return SolidityPackEncoder.getEncoded(enc);
        // Result: bytes contain [map, 42, "hello"] sequentially
    }

    // Decode the above: map, then check for more data
    function decodeMapThenMoreData() public pure returns (
        uint256 mapValueA,
        uint256 mapValueB,
        bool hasMoreData,
        uint256 afterMapNumber,
        string memory afterMapString
    ) {
        bytes memory data = encodeMapThenMoreData();
        SolidityPackTypes.Decoder memory dec = SolidityPackDecoder.newDecoder(data);

        // Decode the map
        uint256 mapLen = SolidityPackDecoder.decodeMapLength(dec);
        require(mapLen == 2, "Expected 2 entries");

        SolidityPackDecoder.decodeString(dec); // key "a"
        mapValueA = SolidityPackDecoder.decodeUint(dec);

        SolidityPackDecoder.decodeString(dec); // key "b"
        mapValueB = SolidityPackDecoder.decodeUint(dec);

        // Check if there's more data after the map
        hasMoreData = SolidityPackDecoder.hasMore(dec);

        // Decode the data after the map
        if (hasMoreData) {
            afterMapNumber = SolidityPackDecoder.decodeUint(dec);
            afterMapString = SolidityPackDecoder.decodeString(dec);
        }

        return (mapValueA, mapValueB, hasMoreData, afterMapNumber, afterMapString);
    }

    // Example 2: What if you declare startMap(2) but encode 3 pairs?
    function encodeMismatchedCount() public pure returns (bytes memory) {
        SolidityPackTypes.Encoder memory enc = SolidityPackEncoder.newEncoder();

        SolidityPackEncoder.startMap(enc, 2); // Declare 2 entries
        SolidityPackEncoder.encodeString(enc, "first");
        SolidityPackEncoder.encodeUint(enc, 1);
        SolidityPackEncoder.encodeString(enc, "second");
        SolidityPackEncoder.encodeUint(enc, 2);
        // Map should be complete according to our declaration

        // But encode a THIRD pair
        SolidityPackEncoder.encodeString(enc, "third");
        SolidityPackEncoder.encodeUint(enc, 3);

        return SolidityPackEncoder.getEncoded(enc);
        // The third pair becomes SEPARATE data after the map!
    }

    // Decode mismatched: shows "third" is outside the map
    function decodeMismatchedCount() public pure returns (
        uint256 mapEntryCount,
        uint256 firstValue,
        uint256 secondValue,
        bool hasDataAfterMap,
        string memory extraKey,
        uint256 extraValue
    ) {
        bytes memory data = encodeMismatchedCount();
        SolidityPackTypes.Decoder memory dec = SolidityPackDecoder.newDecoder(data);

        // Decode the map (declared as 2 entries)
        mapEntryCount = SolidityPackDecoder.decodeMapLength(dec);

        SolidityPackDecoder.decodeString(dec); // "first"
        firstValue = SolidityPackDecoder.decodeUint(dec);

        SolidityPackDecoder.decodeString(dec); // "second"
        secondValue = SolidityPackDecoder.decodeUint(dec);

        // Map is complete, check for more data
        hasDataAfterMap = SolidityPackDecoder.hasMore(dec);

        if (hasDataAfterMap) {
            // The "third" entry is OUTSIDE the map!
            extraKey = SolidityPackDecoder.decodeString(dec);
            extraValue = SolidityPackDecoder.decodeUint(dec);
        }

        return (mapEntryCount, firstValue, secondValue, hasDataAfterMap, extraKey, extraValue);
    }

    // Example 3: Proper way - wrap in array
    function encodeProperlyWithArray() public pure returns (bytes memory) {
        SolidityPackTypes.Encoder memory enc = SolidityPackEncoder.newEncoder();

        // Wrap everything in an array
        SolidityPackEncoder.startArray(enc, 3);

        // Element 1: a map
        SolidityPackEncoder.startMap(enc, 2);
        SolidityPackEncoder.encodeString(enc, "a");
        SolidityPackEncoder.encodeUint(enc, 1);
        SolidityPackEncoder.encodeString(enc, "b");
        SolidityPackEncoder.encodeUint(enc, 2);

        // Element 2: a number
        SolidityPackEncoder.encodeUint(enc, 42);

        // Element 3: a string
        SolidityPackEncoder.encodeString(enc, "hello");

        return SolidityPackEncoder.getEncoded(enc);
    }

    // Example 4: Proper way - wrap in outer map
    function encodeProperlyWithOuterMap() public pure returns (bytes memory) {
        SolidityPackTypes.Encoder memory enc = SolidityPackEncoder.newEncoder();

        // Outer map with 3 entries
        SolidityPackEncoder.startMap(enc, 3);

        // Entry 1: inner map
        SolidityPackEncoder.encodeString(enc, "data");
        SolidityPackEncoder.startMap(enc, 2);
        SolidityPackEncoder.encodeString(enc, "a");
        SolidityPackEncoder.encodeUint(enc, 1);
        SolidityPackEncoder.encodeString(enc, "b");
        SolidityPackEncoder.encodeUint(enc, 2);

        // Entry 2: number
        SolidityPackEncoder.encodeString(enc, "number");
        SolidityPackEncoder.encodeUint(enc, 42);

        // Entry 3: text
        SolidityPackEncoder.encodeString(enc, "text");
        SolidityPackEncoder.encodeString(enc, "hello");

        return SolidityPackEncoder.getEncoded(enc);
    }

    // Demonstrate sequential nature of encoding
    function demonstrateSequentialEncoding() public pure returns (
        bytes memory justMap,
        bytes memory mapPlusOne,
        bytes memory mapPlusTwo,
        bool lengthsMatch
    ) {
        // Encode just the map
        SolidityPackTypes.Encoder memory enc1 = SolidityPackEncoder.newEncoder();
        SolidityPackEncoder.startMap(enc1, 2);
        SolidityPackEncoder.encodeString(enc1, "a");
        SolidityPackEncoder.encodeUint(enc1, 1);
        SolidityPackEncoder.encodeString(enc1, "b");
        SolidityPackEncoder.encodeUint(enc1, 2);
        justMap = SolidityPackEncoder.getEncoded(enc1);

        // Encode map + one more item
        SolidityPackTypes.Encoder memory enc2 = SolidityPackEncoder.newEncoder();
        SolidityPackEncoder.startMap(enc2, 2);
        SolidityPackEncoder.encodeString(enc2, "a");
        SolidityPackEncoder.encodeUint(enc2, 1);
        SolidityPackEncoder.encodeString(enc2, "b");
        SolidityPackEncoder.encodeUint(enc2, 2);
        SolidityPackEncoder.encodeUint(enc2, 42);
        mapPlusOne = SolidityPackEncoder.getEncoded(enc2);

        // Encode map + two more items
        mapPlusTwo = encodeMapThenMoreData();

        // The first encoding should be a prefix of the others
        lengthsMatch = (
            mapPlusOne.length > justMap.length &&
            mapPlusTwo.length > mapPlusOne.length
        );

        return (justMap, mapPlusOne, mapPlusTwo, lengthsMatch);
    }
}
