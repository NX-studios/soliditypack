// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../SolidityPackDecoder.sol";
import "../SolidityPackTypes.sol";

/**
 * @title GenericDecodingExample
 * @notice Example showing how to decode data without knowing types ahead of time
 */
contract GenericDecodingExample {
    using SolidityPackDecoder for *;

    // Example 1: Decode heterogeneous array by inspecting types
    function decodeHeterogeneousArray(bytes memory data) public pure returns (
        uint256 uintCount,
        uint256 stringCount,
        uint256 addressCount
    ) {
        SolidityPackTypes.Decoder memory dec = SolidityPackDecoder.newDecoder(data);

        // Get array length
        uint256 length = SolidityPackDecoder.decodeArrayLength(dec);

        // Iterate through elements and count by type
        for (uint256 i = 0; i < length; i++) {
            SolidityPackDecoder.TypeCategory cat = SolidityPackDecoder.peekCategory(dec);

            if (cat == SolidityPackDecoder.TypeCategory.UINT) {
                uintCount++;
                SolidityPackDecoder.decodeUint(dec); // consume the value
            } else if (cat == SolidityPackDecoder.TypeCategory.STRING) {
                stringCount++;
                SolidityPackDecoder.decodeString(dec);
            } else if (cat == SolidityPackDecoder.TypeCategory.ADDRESS) {
                addressCount++;
                SolidityPackDecoder.decodeAddress(dec);
            } else {
                // Skip unknown types
                SolidityPackDecoder.skip(dec);
            }
        }
    }

    // Example 2: Decode map with unknown schema by checking each key
    function decodeMapDynamic(bytes memory data) public pure returns (
        uint256 numericFieldCount,
        uint256 textFieldCount
    ) {
        SolidityPackTypes.Decoder memory dec = SolidityPackDecoder.newDecoder(data);

        uint256 mapLength = SolidityPackDecoder.decodeMapLength(dec);

        for (uint256 i = 0; i < mapLength; i++) {
            // Skip the key (assuming string keys)
            SolidityPackDecoder.decodeString(dec);

            // Check the value type
            SolidityPackDecoder.TypeCategory valueCat = SolidityPackDecoder.peekCategory(dec);

            if (
                valueCat == SolidityPackDecoder.TypeCategory.UINT ||
                valueCat == SolidityPackDecoder.TypeCategory.INT
            ) {
                numericFieldCount++;
                SolidityPackDecoder.skip(dec);
            } else if (valueCat == SolidityPackDecoder.TypeCategory.STRING) {
                textFieldCount++;
                SolidityPackDecoder.skip(dec);
            } else {
                // Unknown type, skip it
                SolidityPackDecoder.skip(dec);
            }
        }
    }

    // Example 3: Conditionally decode based on type inspection
    function findFirstString(bytes memory data) public pure returns (string memory result, bool found) {
        SolidityPackTypes.Decoder memory dec = SolidityPackDecoder.newDecoder(data);

        uint256 length = SolidityPackDecoder.decodeArrayLength(dec);

        for (uint256 i = 0; i < length; i++) {
            if (SolidityPackDecoder.isCategory(dec, SolidityPackDecoder.TypeCategory.STRING)) {
                result = SolidityPackDecoder.decodeString(dec);
                found = true;
                return (result, found);
            } else {
                SolidityPackDecoder.skip(dec);
            }
        }

        return ("", false);
    }

    // Example 4: Stream processing - read until end
    function processStream(bytes memory data) public pure returns (uint256 itemCount) {
        SolidityPackTypes.Decoder memory dec = SolidityPackDecoder.newDecoder(data);

        uint256 arrayLength = SolidityPackDecoder.decodeArrayLength(dec);

        // Process items one by one without knowing their types
        while (itemCount < arrayLength && SolidityPackDecoder.hasMore(dec)) {
            SolidityPackDecoder.TypeCategory cat = SolidityPackDecoder.peekCategory(dec);

            // Handle different types differently
            if (cat == SolidityPackDecoder.TypeCategory.ARRAY) {
                // Recursively handle nested arrays
                uint256 nestedLen = SolidityPackDecoder.decodeArrayLength(dec);
                for (uint256 i = 0; i < nestedLen; i++) {
                    SolidityPackDecoder.skip(dec);
                }
            } else if (cat == SolidityPackDecoder.TypeCategory.MAP) {
                // Skip maps entirely
                uint256 mapLen = SolidityPackDecoder.decodeMapLength(dec);
                for (uint256 i = 0; i < mapLen * 2; i++) {
                    SolidityPackDecoder.skip(dec);
                }
            } else {
                // Skip simple types
                SolidityPackDecoder.skip(dec);
            }

            itemCount++;
        }
    }

    // Example 5: Extract only addresses from mixed-type array
    function extractAddresses(bytes memory data) public pure returns (address[] memory) {
        SolidityPackTypes.Decoder memory dec = SolidityPackDecoder.newDecoder(data);

        uint256 length = SolidityPackDecoder.decodeArrayLength(dec);

        // First pass: count addresses
        uint256 addressCount = 0;
        uint256 savedPos = dec.pos;

        for (uint256 i = 0; i < length; i++) {
            if (SolidityPackDecoder.isCategory(dec, SolidityPackDecoder.TypeCategory.ADDRESS)) {
                addressCount++;
            }
            SolidityPackDecoder.skip(dec);
        }

        // Reset position
        dec.pos = savedPos;

        // Second pass: extract addresses
        address[] memory addresses = new address[](addressCount);
        uint256 idx = 0;

        for (uint256 i = 0; i < length; i++) {
            if (SolidityPackDecoder.isCategory(dec, SolidityPackDecoder.TypeCategory.ADDRESS)) {
                addresses[idx++] = SolidityPackDecoder.decodeAddress(dec);
            } else {
                SolidityPackDecoder.skip(dec);
            }
        }

        return addresses;
    }

    // Example 6: Validate data structure without full decoding
    function validateStructure(bytes memory data) public pure returns (
        bool valid,
        string memory errorMsg
    ) {
        SolidityPackTypes.Decoder memory dec = SolidityPackDecoder.newDecoder(data);

        // Expect: map with specific structure
        if (!SolidityPackDecoder.isCategory(dec, SolidityPackDecoder.TypeCategory.MAP)) {
            return (false, "Expected map at root");
        }

        uint256 mapLen = SolidityPackDecoder.decodeMapLength(dec);

        if (mapLen < 2) {
            return (false, "Map must have at least 2 fields");
        }

        // Check that all keys are strings
        for (uint256 i = 0; i < mapLen; i++) {
            if (!SolidityPackDecoder.isCategory(dec, SolidityPackDecoder.TypeCategory.STRING)) {
                return (false, "All keys must be strings");
            }
            SolidityPackDecoder.decodeString(dec); // consume key

            // Value can be anything
            SolidityPackDecoder.skip(dec);
        }

        return (true, "");
    }
}
