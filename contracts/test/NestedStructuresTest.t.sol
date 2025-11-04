// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../examples/NestedStructuresExample.sol";

/**
 * @title NestedStructuresTest
 * @notice Test nested structure encoding and decoding
 */
contract NestedStructuresTest {
    NestedStructuresExample example;

    constructor() {
        example = new NestedStructuresExample();
    }

    function testEncodeNestedMap() public view returns (bytes memory) {
        return example.encodeNestedMap();
    }

    function testEncodeMapWithArray() public view returns (bytes memory) {
        return example.encodeMapWithArray();
    }

    function testEncodeComplexNesting() public view returns (bytes memory) {
        return example.encodeComplexNesting();
    }

    function testDecodeNestedMapStepByStep() public view returns (
        uint256 outerValue,
        uint256 nestedInner,
        string memory nestedName
    ) {
        return example.decodeNestedMapStepByStep();
    }

    function testDecodeMapWithArrayUsingInspection() public view returns (
        string memory name,
        uint256 firstScore,
        uint256 scoresCount
    ) {
        return example.decodeMapWithArrayUsingInspection();
    }

    function testDecodeComplexAndExtractTags() public view returns (
        string memory firstTag,
        string memory secondTag,
        bool foundTags
    ) {
        return example.decodeComplexAndExtractTags();
    }

    function testDecodeUnknownStructureWithSkip() public view returns (
        uint256 id,
        uint256 count
    ) {
        return example.decodeUnknownStructureWithSkip();
    }
}
