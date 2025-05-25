const hre = require("hardhat");
const fs = require("fs");

async function main() {
  const Glasanje = await hre.ethers.getContractFactory("DecentraliziranoGlasanje");
  const glasanje = await Glasanje.deploy();

  await glasanje.waitForDeployment();

  const address = await glasanje.getAddress();
  console.log("DecentraliziranoGlasanje deployed to:", address);

  const abi = (await hre.artifacts.readArtifact("DecentraliziranoGlasanje")).abi;

  fs.writeFileSync(
    "./glasanje-frontend/src/contracts/contract-address.json",
    JSON.stringify({ contractAddress: address }, null, 2)
  );

  fs.writeFileSync(
    "./glasanje-frontend/src/contracts/abi.js",
    `export const glasanjeAbi = ${JSON.stringify(abi, null, 2)};`
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
