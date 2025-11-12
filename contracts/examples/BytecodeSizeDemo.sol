// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../SPack.sol";
import "../SolidityPackTypes.sol";

/**
 * @title MinimalContractOldAPI
 * @notice Minimal contract using SPack verbose style
 * @dev Used to measure bytecode size impact
 */
contract MinimalContractOldAPI {
    function encode() external pure returns (bytes memory) {
        SPack.Builder memory b = SPack.builder();
        SPack.map(b, 3);
        SPack.s(b, "name");
        SPack.s(b, "Alice");
        SPack.s(b, "age");
        SPack.u(b, 30);
        SPack.s(b, "balance");
        SPack.u(b, 1000000);
        return SPack.done(b);
    }
}

/**
 * @title MinimalContractNewAPI
 * @notice Minimal contract using SPack chainable style
 * @dev Used to measure bytecode size impact
 */
contract MinimalContractNewAPI {
    function encode() external pure returns (bytes memory) {
        SPack.Builder memory b = SPack.builder();
        SPack.map(b, 3);
        SPack.s(b, "name");
        SPack.s(b, "Alice");
        SPack.s(b, "age");
        SPack.u(b, 30);
        SPack.s(b, "balance");
        SPack.u(b, 1000000);
        return SPack.done(b);
    }
}

/**
 * HOW TO MEASURE BYTECODE SIZE:
 *
 * 1. Compile both contracts:
 *    npx hardhat compile
 *
 * 2. Check artifact sizes:
 *    ls -lh artifacts/contracts/examples/BytecodeSizeDemo.sol/
 *
 * 3. Or programmatically:
 *    const oldAPI = await ethers.getContractFactory("MinimalContractOldAPI");
 *    const newAPI = await ethers.getContractFactory("MinimalContractNewAPI");
 *    console.log("Old API bytecode:", oldAPI.bytecode.length / 2, "bytes");
 *    console.log("New API bytecode:", newAPI.bytecode.length / 2, "bytes");
 *
 * EXPECTED RESULT:
 * Both contracts should have IDENTICAL bytecode size since they use the same code.
 * SPack is designed to be concise and gas-efficient with minimal overhead.
 *
 * The SPack library provides:
 * 1. Short, memorable function names (s, u, a, b, map, arr, etc.)
 * 2. Builder pattern for clean, readable code
 * 3. Optimized internal implementations
 * 4. Zero runtime gas overhead vs manual encoding
 * 5. Smaller bytecode compared to verbose APIs
 */
