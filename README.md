# Proof of Uniqueness

A privacy-preserving uniqueness verification protocol that enables users to prove they are unique participants in any system without revealing their identity or linking across different interactions.

## Overview

The Proof of Uniqueness protocol extends the concept of identity commitments with **nullifier-based verification**. Each user registers a commitment once, then for each unique action they perform, they generate a unique nullifier. The protocol ensures:

1. **Uniqueness** — Each user can only register once per system
2. **Privacy** — No link between registration and verification actions
3. **Double-action prevention** — Each nullifier can only be consumed once
4. **Non-repudiation** — Verifiable proofs of uniqueness

### How It Works

```
┌─────────┐     ┌──────────────────┐     ┌──────────────┐
│  User   │────▶│ UniquenessPool   │────▶│ Nullifier    │
│         │     │ • Register       │     │ Registry     │
│         │     │ • Verify         │     │ • consume()  │
│         │     │ • Track counts   │     │ • isUsed()   │
└─────────┘     └──────────────────┘     └──────────────┘
```

## Architecture

```
┌──────────────────────────────────────────────────────┐
│                   UniquenessPool                       │
├──────────────────────────────────────────────────────┤
│ · commitments (mapping: bytes32 → bool)               │
│ · commitmentList (bytes32[])                          │
│ · nullifierRegistry (NullifierRegistry)               │
├──────────────────────────────────────────────────────┤
│ + register(commitment)                                 │
│ + verifyUniqueness(commitment, nullifier, proof)      │
│ + isNullified(nullifier) → bool                      │
│ + getRegisteredCount() → uint256                      │
└──────────────────────────────────────────────────────┘
            │
            ▼
┌──────────────────────────────────────────────────────┐
│                 NullifierRegistry                      │
├──────────────────────────────────────────────────────┤
│ · nullifiers (mapping: bytes32 → bool)                │
├──────────────────────────────────────────────────────┤
│ + consume(nullifier)                                   │
│ + isConsumed(nullifier) → bool                       │
└──────────────────────────────────────────────────────┘
```

## Contracts

| Contract | Description |
|----------|-------------|
| **UniquenessPool.sol** | Main pool — manages identity commitments, coordinates with NullifierRegistry, and verifies uniqueness proofs |
| **NullifierRegistry.sol** | Standalone registry for tracking consumed nullifiers — prevents replay attacks and double-use |
| **UniquenessVerifier.sol** | Interface and mock verifier for ZK uniqueness proofs |

## Comparison: Tornado Cash vs Uniqueness Pool

| Feature | Tornado Cash | Uniqueness Pool |
|---------|-------------|-----------------|
| Purpose | Privacy for transfers | Uniqueness verification |
| Mechanism | Deposit/Withdraw with Merkle proofs | Register/Verify with nullifiers |
| Reuse | One-time per deposit | Multi-use with nullifiers |
| Focus | Anonymity | Anti-sybil |

## Getting Started

### Installation

```bash
git clone https://github.com/zkpersonood/proof-of-uniqueness.git
cd proof-of-uniqueness
npm install
npx hardhat compile
npx hardhat test
```

### Deploy

```bash
npx hardhat run scripts/deploy.js --network sepolia
```

## Use Cases

- **Quadratic Voting** — Prevent multiple votes from same identity
- **Token Distributions** — Fair airdrops with one-claim-per-person guarantees
- **Discriminant Polling** — Anonymous polls with verified uniqueness
- **Reputation Systems** — Unique participation tracking without identity linkage

## License

MIT
