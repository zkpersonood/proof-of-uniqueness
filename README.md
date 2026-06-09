# Proof of Uniqueness

An on-chain uniqueness proof system that allows users to prove they are unique participants without linking to any identity.

## Contracts

- **UniquenessPool.sol** — Pool of verified unique identities with nullifier tracking to prevent double-use
- **NullifierRegistry.sol** — Registry tracking consumed nullifiers while preserving privacy
- **UniquenessVerifier.sol** — Interface for uniqueness verification

## How it works

1. Users register an identity commitment
2. To prove uniqueness, they submit a nullifier + ZK proof
3. The pool verifies the proof and consumes the nullifier
4. Each nullifier can only be used once

## Getting Started

```bash
npm install
npx hardhat compile
npx hardhat test
```
