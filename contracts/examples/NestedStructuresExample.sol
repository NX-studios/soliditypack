// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../SPack.sol";
import "../SolidityPackDecoder.sol";
import "../SolidityPackTypes.sol";

/**
 * @title NestedStructuresExample
 * @notice Demonstrates encoding and decoding nested maps and arrays
 */
contract NestedStructuresExample {
    using SPack for *;
    using SolidityPackDecoder for *;

    // Example 1: Map with nested map
    // Structure: {outer: 42, nested: {inner: 100, name: "test"}}
    function encodeNestedMap() public pure returns (bytes memory) {
        SPack.Builder memory b = SPack.builder();
        SPack.map(b, 2);              // Outer map: 2 entries
        SPack.s(b, "outer");          // Entry 1: key
        SPack.u(b, 42);               // Entry 1: value
        SPack.s(b, "nested");         // Entry 2: key
        SPack.map(b, 2);              // Entry 2: value is a MAP!
        SPack.s(b, "inner");          // Nested key 1
        SPack.u(b, 100);              // Nested value 1
        SPack.s(b, "name");           // Nested key 2
        SPack.s(b, "test");           // Nested value 2
        return SPack.done(b);
    }

    // Example 2: Map with array value
    // Structure: {name: "Alice", scores: [10, 20, 30]}
    function encodeMapWithArray() public pure returns (bytes memory) {
        SPack.Builder memory b = SPack.builder();
        SPack.map(b, 2);
        SPack.s(b, "name");
        SPack.s(b, "Alice");
        SPack.s(b, "scores");
        SPack.arr(b, 3);              // Array as value!
        SPack.u(b, 10);
        SPack.u(b, 20);
        SPack.u(b, 30);
        return SPack.done(b);
    }

    // Example 3: Complex nesting
    // Structure: {id: 1, data: {tags: ["a", "b"], active: true}, count: 5}
    function encodeComplexNesting() public pure returns (bytes memory) {
        SPack.Builder memory b = SPack.builder();
        SPack.map(b, 3);              // Level 1: Map with 3 entries
        SPack.s(b, "id");
        SPack.u(b, 1);
        SPack.s(b, "data");
        SPack.map(b, 2);              // Level 2: Nested map
        SPack.s(b, "tags");
        SPack.arr(b, 2);              // Level 3: Array in nested map
        SPack.s(b, "a");
        SPack.s(b, "b");
        SPack.s(b, "active");
        SPack.bool_(b, true);
        SPack.s(b, "count");
        SPack.u(b, 5);
        return SPack.done(b);
    }

    // Decode Example 1: Step by step
    function decodeNestedMapStepByStep() public pure returns (
        uint256 outerValue,
        uint256 nestedInner,
        string memory nestedName
    ) {
        // Get encoded data
        bytes memory data = encodeNestedMap();
        SolidityPackTypes.Decoder memory dec = SolidityPackDecoder.newDecoder(data);

        // Step 1: Decode outer map
        uint256 outerLen = SolidityPackDecoder.decodeMapLength(dec);
        require(outerLen == 2, "Expected 2 entries");

        // Step 2: Decode first entry
        string memory key1 = SolidityPackDecoder.decodeString(dec);
        require(keccak256(bytes(key1)) == keccak256("outer"), "Expected 'outer'");
        outerValue = SolidityPackDecoder.decodeUint(dec);

        // Step 3: Decode second entry key
        string memory key2 = SolidityPackDecoder.decodeString(dec);
        require(keccak256(bytes(key2)) == keccak256("nested"), "Expected 'nested'");

        // Step 4: Check that value is a map
        SolidityPackDecoder.TypeCategory cat = SolidityPackDecoder.peekCategory(dec);
        require(cat == SolidityPackDecoder.TypeCategory.MAP, "Expected nested map");

        // Step 5: Decode nested map
        uint256 nestedLen = SolidityPackDecoder.decodeMapLength(dec);
        require(nestedLen == 2, "Expected 2 nested entries");

        // Nested entry 1
        SolidityPackDecoder.decodeString(dec); // key "inner"
        nestedInner = SolidityPackDecoder.decodeUint(dec);

        // Nested entry 2
        SolidityPackDecoder.decodeString(dec); // key "name"
        nestedName = SolidityPackDecoder.decodeString(dec);

        return (outerValue, nestedInner, nestedName);
    }

    // Decode Example 2: Using type inspection
    function decodeMapWithArrayUsingInspection() public pure returns (
        string memory name,
        uint256 firstScore,
        uint256 scoresCount
    ) {
        bytes memory data = encodeMapWithArray();
        SolidityPackTypes.Decoder memory dec = SolidityPackDecoder.newDecoder(data);

        uint256 mapLen = SolidityPackDecoder.decodeMapLength(dec);

        for (uint256 i = 0; i < mapLen; i++) {
            string memory key = SolidityPackDecoder.decodeString(dec);

            if (keccak256(bytes(key)) == keccak256("name")) {
                // We know this is a string
                name = SolidityPackDecoder.decodeString(dec);
            } else if (keccak256(bytes(key)) == keccak256("scores")) {
                // Check if it's an array
                require(
                    SolidityPackDecoder.isCategory(dec, SolidityPackDecoder.TypeCategory.ARRAY),
                    "Expected array"
                );

                scoresCount = SolidityPackDecoder.decodeArrayLength(dec);
                firstScore = SolidityPackDecoder.decodeUint(dec);

                // Skip the rest of the array
                for (uint256 j = 1; j < scoresCount; j++) {
                    SolidityPackDecoder.skip(dec);
                }
            } else {
                // Unknown field, skip it
                SolidityPackDecoder.skip(dec);
            }
        }

        return (name, firstScore, scoresCount);
    }

    // Decode Example 3: Generic decoding with recursion-like pattern
    function decodeComplexAndExtractTags() public pure returns (
        string memory firstTag,
        string memory secondTag,
        bool foundTags
    ) {
        bytes memory data = encodeComplexNesting();
        SolidityPackTypes.Decoder memory dec = SolidityPackDecoder.newDecoder(data);

        uint256 mapLen = SolidityPackDecoder.decodeMapLength(dec);

        for (uint256 i = 0; i < mapLen; i++) {
            string memory key = SolidityPackDecoder.decodeString(dec);

            if (keccak256(bytes(key)) == keccak256("data")) {
                // This is the nested map we want
                uint256 dataMapLen = SolidityPackDecoder.decodeMapLength(dec);

                for (uint256 j = 0; j < dataMapLen; j++) {
                    string memory nestedKey = SolidityPackDecoder.decodeString(dec);

                    if (keccak256(bytes(nestedKey)) == keccak256("tags")) {
                        // Found the tags array!
                        uint256 tagsLen = SolidityPackDecoder.decodeArrayLength(dec);
                        if (tagsLen >= 2) {
                            firstTag = SolidityPackDecoder.decodeString(dec);
                            secondTag = SolidityPackDecoder.decodeString(dec);
                            foundTags = true;

                            // Skip remaining tags
                            for (uint256 k = 2; k < tagsLen; k++) {
                                SolidityPackDecoder.skip(dec);
                            }
                        }
                    } else {
                        // Skip other nested fields
                        SolidityPackDecoder.skip(dec);
                    }
                }
            } else {
                // Skip other top-level fields
                SolidityPackDecoder.skip(dec);
            }
        }

        return (firstTag, secondTag, foundTags);
    }

    // Example: What if you start a map but then need to skip unknown nested structures?
    function decodeUnknownStructureWithSkip() public pure returns (
        uint256 id,
        uint256 count
    ) {
        bytes memory data = encodeComplexNesting();
        SolidityPackTypes.Decoder memory dec = SolidityPackDecoder.newDecoder(data);

        uint256 mapLen = SolidityPackDecoder.decodeMapLength(dec);

        for (uint256 i = 0; i < mapLen; i++) {
            string memory key = SolidityPackDecoder.decodeString(dec);

            if (keccak256(bytes(key)) == keccak256("id")) {
                id = SolidityPackDecoder.decodeUint(dec);
            } else if (keccak256(bytes(key)) == keccak256("count")) {
                count = SolidityPackDecoder.decodeUint(dec);
            } else {
                // Skip the entire "data" nested map without caring about its structure!
                // The skip() function handles nested structures automatically
                SolidityPackDecoder.skip(dec);
            }
        }

        return (id, count);
    }
}
