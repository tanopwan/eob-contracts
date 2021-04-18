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

  const WBNB = await hre.ethers.getContractFactory("contracts/WBNB.sol:WBNB");
  const wBNB = await WBNB.deploy();
  await wBNB.deployed();
  console.log("WBNB deployed to:", wBNB.address);

  const EOBToken = await hre.ethers.getContractFactory("EOBToken");
  const eobToken = await EOBToken.deploy();
  await eobToken.deployed();
  console.log("EOBToken deployed to:", eobToken.address);

  const PancakeFactory = await hre.ethers.getContractFactory("PancakeFactory");
  const pancakeFactory = await PancakeFactory.deploy(owner.address);
  await pancakeFactory.deployed();
  console.log("PancakeFactory deployed to:", pancakeFactory.address);

  const PancakeRouter = await hre.ethers.getContractFactory("PancakeRouter");
  console.log(PancakeRouter);
  const pancakeRouter = await PancakeRouter.deploy(pancakeFactory.address, wBNB.address);
  await pancakeRouter.deployed();
  console.log("PancakeRouter deployed to:", pancakeRouter.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });