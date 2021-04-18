// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile 
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const [owner] = await ethers.getSigners();

  const CakeToken = await hre.ethers.getContractFactory("CakeToken");
  const cakeToken = await CakeToken.deploy();
  await cakeToken.deployed();
  console.log("CakeToken deployed to:", cakeToken.address);

  const SyrupBar = await hre.ethers.getContractFactory("SyrupBar");
  const syrupBar = await SyrupBar.deploy(cakeToken.address);
  await syrupBar.deployed();
  console.log("SyrupBar deployed to:", syrupBar.address);

  const MasterChef = await hre.ethers.getContractFactory("contracts/MasterChefPancake.sol:MasterChef");
  const masterChef = await MasterChef.deploy(cakeToken.address, syrupBar.address, owner.address, new hre.ethers.BigNumber.from("10000000000000000000"), 1);
  await masterChef.deployed();
  console.log("MasterChef deployed to:", masterChef.address);

  await cakeToken.transferOwnership(masterChef.address);
  await syrupBar.transferOwnership(masterChef.address);

  const cakeTokenOwner = await cakeToken.getOwner()
  console.log("CakeToken ownership transfered to:", cakeTokenOwner);

  const syrupBarOwner = await syrupBar.getOwner()
  console.log("SyrupBar ownership transfered to:", syrupBarOwner);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });