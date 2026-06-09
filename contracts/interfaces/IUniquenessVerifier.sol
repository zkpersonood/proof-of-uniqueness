// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title IUniquenessVerifier
/// @notice Interface for a ZK-verifier that checks an identity commitment
///         proof-of-uniqueness without revealing the underlying identity.
interface IUniquenessVerifier {
    /// @notice Verify a zero-knowledge proof that the prover knows a valid
    ///         identity commitment (e.g. hash of a secret) that has not been
    ///         previously registered.
    /// @param proof  The ZK proof bytes (e.g. Groth16 proof).
    /// @param publicInputs  Any public inputs the verifier needs (e.g. a
    ///        nullifier hash, merkle root, etc.)
    /// @return true if the proof is valid.
    function verifyProof(
        bytes calldata proof,
        uint256[] calldata publicInputs
    ) external view returns (bool);
}
