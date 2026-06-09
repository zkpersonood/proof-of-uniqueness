// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IUniquenessVerifier } from "./interfaces/IUniquenessVerifier.sol";
import { NullifierRegistry } from "./NullifierRegistry.sol";

/// @title UniquenessPool
/// @notice Pool of verified unique identities. Users submit a ZK proof that
///         they know a secret commitment to an identity, along with a
///         nullifier derived from that secret.  If the proof is valid and
///         the nullifier has not been used before, the user is added to the
///         pool and receives a "unique identity" token (represented as an
///         incrementing id).  No link between the deposited commitment and
///         the user's address is ever stored on-chain.
///
///         Inspired by Tornado Cash but generalised for identity proofs.
contract UniquenessPool {
    // --- Types ---

    /// @notice A deposit record in the pool.
    struct Deposit {
        uint256 commitment;      // hash of user's secret
        uint256 nullifier;       // derived from the secret, prevents double-use
        uint256 timestamp;       // when the deposit was accepted
    }

    // --- State ---

    /// @notice The ZK verifier used to validate proofs.
    IUniquenessVerifier public immutable verifier;

    /// @notice The nullifier registry that ensures one-use-only.
    NullifierRegistry public immutable nullifierRegistry;

    /// @notice The Merkle tree root of all accepted commitments.
    ///         Updated every time a new deposit is accepted.
    bytes32 public merkleRoot;

    /// @notice Number of deposits made so far.
    uint256 public depositCount;

    /// @notice The fixed depth of the Merkle tree.
    uint256 public constant TREE_DEPTH = 20;

    /// @notice The maximum number of leaves the tree can hold (2^20).
    uint256 public constant MAX_LEAVES = 1 << TREE_DEPTH;

    /// @notice Storage for active deposits (by deposit index).
    mapping(uint256 => Deposit) private _deposits;

    /// @notice Internal Merkle tree frontier (last-path leaves).
    mapping(uint256 => bytes32[TREE_DEPTH]) private _frontier;

    // --- Events ---

    /// @dev Emitted when a new deposit is successfully made.
    event DepositAdded(
        uint256 indexed index,
        uint256 commitment,
        uint256 nullifier,
        uint256 timestamp
    );

    // --- Errors ---

    error PoolFull();
    error InvalidProof();
    error NullifierAlreadyUsed();
    error ZeroCommitment();

    // --- Constructor ---

    /// @param _verifier         The ZK verifier contract address.
    /// @param _nullifierRegistry The nullifier registry contract address.
    constructor(
        address _verifier,
        address _nullifierRegistry
    ) {
        verifier = IUniquenessVerifier(_verifier);
        nullifierRegistry = NullifierRegistry(_nullifierRegistry);
    }

    // --- External ---

    /// @notice Submit a ZK proof together with a commitment and nullifier.
    ///         If the proof is valid and the nullifier is fresh, the user
    ///         is added to the pool and the Merkle root is updated.
    /// @param proof       The ZK proof bytes.
    /// @param commitment  The identity commitment (hash of secret).
    /// @param nullifier   The nullifier derived from the secret.
    function deposit(
        bytes calldata proof,
        uint256 commitment,
        uint256 nullifier
    ) external {
        if (commitment == 0) revert ZeroCommitment();

        // 1. Check nullifier has not been used.
        if (!nullifierRegistry.isNullifierUnused(nullifier))
            revert NullifierAlreadyUsed();

        // 2. Verify the ZK proof.
        uint256[] memory publicInputs = new uint256[](2);
        publicInputs[0] = commitment;
        publicInputs[1] = nullifier;

        if (!verifier.verifyProof(proof, publicInputs))
            revert InvalidProof();

        // 3. Consume the nullifier (prevents replay).
        nullifierRegistry.consumeNullifier(nullifier);

        // 4. Store the deposit.
        if (depositCount >= MAX_LEAVES) revert PoolFull();
        uint256 idx = depositCount;
        _deposits[idx] = Deposit({
            commitment: commitment,
            nullifier: nullifier,
            timestamp: block.timestamp
        });
        depositCount = idx + 1;

        // 5. Update the incremental Merkle tree.
        _insertLeaf(keccak256(abi.encodePacked(commitment, nullifier)));

        emit DepositAdded(idx, commitment, nullifier, block.timestamp);
    }

    /// @notice Read a deposit by its index.
    /// @param index  The deposit index.
    /// @return The Deposit struct.
    function getDeposit(uint256 index) external view returns (Deposit memory) {
        require(index < depositCount, "UniquenessPool: out of bounds");
        return _deposits[index];
    }

    // --- Internal ---

    /// @notice Incremental Merkle tree insert (append-only, fixed depth).
    ///         Uses the standard "Poseidon-friendly" approach with keccak256
    ///         for EVF-friendliness.
    function _insertLeaf(bytes32 leaf) internal {
        bytes32 hash = leaf;
        for (uint256 i = 0; i < TREE_DEPTH; i++) {
            if (_frontier[depositCount - 1][i] == bytes32(0)) {
                _frontier[depositCount - 1][i] = hash;
                hash = keccak256(abi.encodePacked(
                    _frontier[depositCount - 1][i],
                    bytes32(0) // default zero sibling
                ));
            } else {
                hash = keccak256(abi.encodePacked(
                    _frontier[depositCount - 1][i],
                    hash
                ));
            }
        }
        merkleRoot = hash;
    }
}
