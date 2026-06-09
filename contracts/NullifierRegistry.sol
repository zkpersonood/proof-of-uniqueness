// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IUniquenessVerifier } from "./interfaces/IUniquenessVerifier.sol";

/// @title NullifierRegistry
/// @notice Tracks nullifiers to prevent double-use while preserving privacy.
///         A nullifier is a public value derived from a user's secret that
///         cannot be linked back to the original identity commitment.
///         Once a nullifier is consumed, it can never be reused.
contract NullifierRegistry {
    /// @dev Emitted when a nullifier is consumed (first use).
    event NullifierConsumed(uint256 indexed nullifier, address indexed caller);

    /// @dev Storage: mapping of nullifier → block number when consumed (0 = unused).
    mapping(uint256 => uint256) private _nullifiers;

    /// @notice Check whether a nullifier has already been used.
    /// @param nullifier  The nullifier to check.
    /// @return true if the nullifier has never been consumed.
    function isNullifierUnused(uint256 nullifier) external view returns (bool) {
        return _nullifiers[nullifier] == 0;
    }

    /// @notice Atomically check and mark a nullifier as used.
    ///         Reverts if the nullifier was already consumed.
    /// @param nullifier  The nullifier to consume.
    function consumeNullifier(uint256 nullifier) external {
        require(_nullifiers[nullifier] == 0, "NullifierRegistry: already consumed");
        _nullifiers[nullifier] = block.number;
        emit NullifierConsumed(nullifier, msg.sender);
    }

    /// @notice The block number at which the nullifier was consumed (0 if unused).
    /// @param nullifier  The nullifier to query.
    function blockUsed(uint256 nullifier) external view returns (uint256) {
        return _nullifiers[nullifier];
    }
}
