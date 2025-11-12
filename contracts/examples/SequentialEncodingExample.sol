// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../SPack.sol";
import "../SolidityPackDecoder.sol";
import "../SolidityPackTypes.sol";

/**
 * @title SequentialEncodingExample
 * @notice Demonstrates what happens when you encode data after a map
 */
contract SequentialEncodingExample {
    using SPack for *;
    using SolidityPackDecoder for *;

    // Example 1: Map with 2 entries, then more data after
    function encodeMapThenMoreData() public pure returns (bytes memory) {
        SPack.Builder memory b = SPack.builder();
        // Encode a map with 2 entries
        SPack.map(b, 2);
        SPack.s(b, "a");
        SPack.u(b, 1);
        SPack.s(b, "b");
        SPack.u(b, 2);
        // Map is now complete (2 entries encoded)

        // Now encode MORE items AFTER the map
        SPack.u(b, 42);
        SPack.s(b, "hello");

        return SPack.done(b);
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
        SPack.Builder memory b = SPack.builder();
        SPack.map(b, 2); // Declare 2 entries
        SPack.s(b, "first");
        SPack.u(b, 1);
        SPack.s(b, "second");
        SPack.u(b, 2);
        // Map should be complete according to our declaration

        // But encode a THIRD pair
        SPack.s(b, "third");
        SPack.u(b, 3);

        return SPack.done(b);
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
        SPack.Builder memory b = SPack.builder();
        // Wrap everything in an array
        SPack.arr(b, 3);
        // Element 1: a map
        SPack.map(b, 2);
        SPack.s(b, "a");
        SPack.u(b, 1);
        SPack.s(b, "b");
        SPack.u(b, 2);
        // Element 2: a number
        SPack.u(b, 42);
        // Element 3: a string
        SPack.s(b, "hello");
        return SPack.done(b);
    }

    // Example 4: Proper way - wrap in outer map
    function encodeProperlyWithOuterMap() public pure returns (bytes memory) {
        SPack.Builder memory b = SPack.builder();
        // Outer map with 3 entries
        SPack.map(b, 3);
        // Entry 1: inner map
        SPack.s(b, "data");
        SPack.map(b, 2);
        SPack.s(b, "a");
        SPack.u(b, 1);
        SPack.s(b, "b");
        SPack.u(b, 2);
        // Entry 2: number
        SPack.s(b, "number");
        SPack.u(b, 42);
        // Entry 3: text
        SPack.s(b, "text");
        SPack.s(b, "hello");
        return SPack.done(b);
    }

    // Demonstrate sequential nature of encoding
    function demonstrateSequentialEncoding() public pure returns (
        bytes memory justMap,
        bytes memory mapPlusOne,
        bytes memory mapPlusTwo,
        bool lengthsMatch
    ) {
        // Encode just the map
        SPack.Builder memory b1 = SPack.builder();
        SPack.map(b1, 2);
        SPack.s(b1, "a");
        SPack.u(b1, 1);
        SPack.s(b1, "b");
        SPack.u(b1, 2);
        justMap = SPack.done(b1);

        // Encode map + one more item
        SPack.Builder memory b2 = SPack.builder();
        SPack.map(b2, 2);
        SPack.s(b2, "a");
        SPack.u(b2, 1);
        SPack.s(b2, "b");
        SPack.u(b2, 2);
        SPack.u(b2, 42);
        mapPlusOne = SPack.done(b2);

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
