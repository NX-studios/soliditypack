// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../examples/SequentialEncodingExample.sol";

/**
 * @title SequentialEncodingTest
 * @notice Tests for sequential encoding
 */
contract SequentialEncodingTest {
    SequentialEncodingExample example;

    constructor() {
        example = new SequentialEncodingExample();
    }

    function testEncodeMapThenMoreData() public view returns (bytes memory) {
        return example.encodeMapThenMoreData();
    }

    function testDecodeMapThenMoreData() public view returns (
        uint256 mapValueA,
        uint256 mapValueB,
        bool hasMoreData,
        uint256 afterMapNumber,
        string memory afterMapString
    ) {
        return example.decodeMapThenMoreData();
    }

    function testEncodeMismatchedCount() public view returns (bytes memory) {
        return example.encodeMismatchedCount();
    }

    function testDecodeMismatchedCount() public view returns (
        uint256 mapEntryCount,
        uint256 firstValue,
        uint256 secondValue,
        bool hasDataAfterMap,
        string memory extraKey,
        uint256 extraValue
    ) {
        return example.decodeMismatchedCount();
    }

    function testEncodeProperlyWithArray() public view returns (bytes memory) {
        return example.encodeProperlyWithArray();
    }

    function testEncodeProperlyWithOuterMap() public view returns (bytes memory) {
        return example.encodeProperlyWithOuterMap();
    }

    function testDemonstrateSequentialEncoding() public view returns (
        bytes memory justMap,
        bytes memory mapPlusOne,
        bytes memory mapPlusTwo,
        bool lengthsMatch
    ) {
        return example.demonstrateSequentialEncoding();
    }
}
