const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying with account:", deployer.address);

  // 1. Deploy NullifierRegistry
  const NullifierRegistry = await ethers.getContractFactory("NullifierRegistry");
  const nullifierRegistry = await NullifierRegistry.deploy();
  await nullifierRegistry.waitForDeployment();
  console.log("NullifierRegistry deployed to:", await nullifierRegistry.getAddress());

  // 2. Deploy UniquenessVerifier (stub — replace VK hash for production)
  const verifyingKeyHash = ethers.keccak256(
    ethers.toUtf8Bytes("production-verifying-key")
  );
  const Verifier = await ethers.getContractFactory("UniquenessVerifier");
  const verifier = await Verifier.deploy(verifyingKeyHash);
  await verifier.waitForDeployment();
  console.log("UniquenessVerifier deployed to:", await verifier.getAddress());

  // 3. Deploy UniquenessPool
  const Pool = await ethers.getContractFactory("UniquenessPool");
  const pool = await Pool.deploy(
    await verifier.getAddress(),
    await nullifierRegistry.getAddress()
  );
  await pool.waitForDeployment();
  console.log("UniquenessPool deployed to:", await pool.getAddress());

  console.log("\nDeployment complete.");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
