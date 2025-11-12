// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../SPack.sol";
import "../SolidityPackTypes.sol";

/**
 * @title ImprovedAPIExample
 * @notice Demonstrates the improved SPack API for encoding objects
 * @dev Shows both the old verbose way and the new concise way
 */
contract ImprovedAPIExample {

    /**
     * @notice OLD WAY: Verbose encoding with separate key and value calls
     * @dev Requires 2 lines per field (encodeKey + encodeValue)
     */
    function encodeUserDataOldWay() public pure returns (bytes memory) {
        SPack.Builder memory b = SPack.builder();
        SPack.map(b, 4);
        SPack.s(b, "name");
        SPack.s(b, "Alice");
        SPack.s(b, "age");
        SPack.u(b, 30);
        SPack.s(b, "active");
        SPack.bool_(b, true);
        SPack.s(b, "balance");
        SPack.u(b, 1000000);
        return SPack.done(b);
    }

    /**
     * @notice NEW WAY: Concise encoding with SPack builder
     * @dev Same as old way - SPack is already concise!
     */
    function encodeUserDataNewWay() public pure returns (bytes memory) {
        SPack.Builder memory b = SPack.builder();
        SPack.map(b, 4);
        SPack.s(b, "name");
        SPack.s(b, "Alice");
        SPack.s(b, "age");
        SPack.u(b, 30);
        SPack.s(b, "active");
        SPack.bool_(b, true);
        SPack.s(b, "balance");
        SPack.u(b, 1000000);
        return SPack.done(b);
    }

    /**
     * @notice Example with complex types including arrays and addresses
     */
    function encodeComplexObject() public pure returns (bytes memory) {
        // Create some test data
        uint256[] memory scores = new uint256[](3);
        scores[0] = 95;
        scores[1] = 87;
        scores[2] = 92;

        address[] memory addresses = new address[](2);
        addresses[0] = 0x742d35cC6634c0532925A3b844bc9E7595F0beB1;
        addresses[1] = 0x1234567890123456789012345678901234567890;

        SPack.Builder memory b = SPack.builder();
        SPack.map(b, 5);
        SPack.s(b, "name");
        SPack.s(b, "Bob");
        SPack.s(b, "wallet");
        SPack.a(b, 0x742d35cC6634c0532925A3b844bc9E7595F0beB1);
        SPack.s(b, "hash");
        SPack.b32(b, keccak256("test"));
        SPack.s(b, "scores");
        SPack.arr(b, scores.length);
        for (uint256 i = 0; i < scores.length; i++) {
            SPack.u(b, scores[i]);
        }
        SPack.s(b, "contacts");
        SPack.arr(b, addresses.length);
        for (uint256 i = 0; i < addresses.length; i++) {
            SPack.a(b, addresses[i]);
        }
        return SPack.done(b);
    }

    /**
     * @notice Nested object example - you can still use manual control for nesting
     */
    function encodeNestedObject() public pure returns (bytes memory) {
        SPack.Builder memory b = SPack.builder();
        SPack.map(b, 3);
        SPack.s(b, "userId");
        SPack.s(b, "user123");
        SPack.s(b, "version");
        SPack.u(b, 1);
        SPack.s(b, "settings");
        SPack.map(b, 2);
        SPack.s(b, "notifications");
        SPack.bool_(b, true);
        SPack.s(b, "theme");
        SPack.s(b, "dark");
        return SPack.done(b);
    }

    /**
     * @notice Real-world example: Encode transaction data
     */
    function encodeTransaction(
        address from,
        address to,
        uint256 amount,
        uint256 nonce,
        bytes32 txHash
    ) public pure returns (bytes memory) {
        SPack.Builder memory b = SPack.builder();
        SPack.map(b, 5);
        SPack.s(b, "from");
        SPack.a(b, from);
        SPack.s(b, "to");
        SPack.a(b, to);
        SPack.s(b, "amount");
        SPack.u(b, amount);
        SPack.s(b, "nonce");
        SPack.u(b, nonce);
        SPack.s(b, "txHash");
        SPack.b32(b, txHash);
        return SPack.done(b);
    }
}
