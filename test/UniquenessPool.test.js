const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("UniquenessPool", function () {
  let verifier, nullifierRegistry, pool;
  let owner, user1, user2;

  before(async function () {
    [owner, user1, user2] = await ethers.getSigners();
  });

  beforeEach(async function () {
    // Deploy the stub verifier
    const Verifier = await ethers.getContractFactory("UniquenessVerifier");
    verifier = await Verifier.connect(owner).deploy(
      ethers.keccak256(ethers.toUtf8Bytes("test-vk"))
    );
    await verifier.waitForDeployment();

    // Deploy the nullifier registry
    const NullifierRegistry = await ethers.getContractFactory("NullifierRegistry");
    nullifierRegistry = await NullifierRegistry.connect(owner).deploy();
    await nullifierRegistry.waitForDeployment();

    // Deploy the pool
    const Pool = await ethers.getContractFactory("UniquenessPool");
    pool = await Pool.connect(owner).deploy(
      await verifier.getAddress(),
      await nullifierRegistry.getAddress()
    );
    await pool.waitForDeployment();
  });

  describe("Deployment", function () {
    it("should set the verifier and nullifier registry addresses", async function () {
      expect(await pool.verifier()).to.equal(await verifier.getAddress());
      expect(await pool.nullifierRegistry()).to.equal(
        await nullifierRegistry.getAddress()
      );
    });

    it("should start with zero deposits", async function () {
      expect(await pool.depositCount()).to.equal(0);
    });

    it("should have a zero merkle root initially", async function () {
      expect(await pool.merkleRoot()).to.equal(
        "0x0000000000000000000000000000000000000000000000000000000000000000"
      );
    });
  });

  describe("Deposits", function () {
    it("should accept a valid deposit", async function () {
      const commitment = ethers.keccak256(ethers.toUtf8Bytes("secret-identity-1"));
      const nullifier = ethers.keccak256(ethers.toUtf8Bytes("nullifier-1"));

      // The stub verifier accepts any non-empty array, so we pass dummy proof
      const proof = ethers.hexlify(ethers.randomBytes(128));

      const tx = await pool.connect(user1).deposit(proof, commitment, nullifier);

      // Check event emitted
      await expect(tx).to.emit(pool, "DepositAdded");

      expect(await pool.depositCount()).to.equal(1);

      const deposit = await pool.getDeposit(0);
      expect(deposit.commitment).to.equal(commitment);
      expect(deposit.nullifier).to.equal(nullifier);
    });

    it("should reject a duplicate nullifier", async function () {
      const commitment = ethers.keccak256(ethers.toUtf8Bytes("secret-2"));
      const nullifier = ethers.keccak256(ethers.toUtf8Bytes("nullifier-2"));
      const proof = ethers.hexlify(ethers.randomBytes(128));

      await pool.connect(user1).deposit(proof, commitment, nullifier);

      // Second deposit with same nullifier should revert with custom error
      const commitment2 = ethers.keccak256(ethers.toUtf8Bytes("secret-3"));
      await expect(
        pool.connect(user2).deposit(proof, commitment2, nullifier)
      ).to.be.revertedWithCustomError(pool, "NullifierAlreadyUsed");
    });

    it("should reject a zero commitment", async function () {
      const nullifier = ethers.keccak256(ethers.toUtf8Bytes("nullifier-3"));
      const proof = ethers.hexlify(ethers.randomBytes(128));

      await expect(
        pool.connect(user1).deposit(proof, 0, nullifier)
      ).to.be.revertedWithCustomError(pool, "ZeroCommitment");
    });

    it("should update the merkle root after a deposit", async function () {
      const commitment = ethers.keccak256(ethers.toUtf8Bytes("secret-4"));
      const nullifier = ethers.keccak256(ethers.toUtf8Bytes("nullifier-4"));
      const proof = ethers.hexlify(ethers.randomBytes(128));

      await pool.connect(user1).deposit(proof, commitment, nullifier);

      const root = await pool.merkleRoot();
      expect(root).to.not.equal(
        "0x0000000000000000000000000000000000000000000000000000000000000000"
      );
    });
  });
});
