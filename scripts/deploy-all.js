// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { ethers } = require("hardhat");
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

  const WBNB = await hre.ethers.getContractFactory("contracts/WBNB.sol:WBNB");
  const wBNB = await WBNB.deploy();
  await wBNB.deployed();
  console.log("WBNB deployed to:", wBNB.address);

  const EOBToken = await hre.ethers.getContractFactory("EOBToken");
  const eobToken = await EOBToken.deploy();
  await eobToken.deployed();
  console.log("EOBToken deployed to:", eobToken.address);
  // await eobToken.setAllowMinting(owner.address, true);
  // await eobToken.setAllowMinting(owner.address, true);

  const PancakeFactory = await hre.ethers.getContractFactory("PancakeFactory");
  const pancakeFactory = await PancakeFactory.deploy(owner.address);
  await pancakeFactory.deployed();
  console.log("PancakeFactory deployed to:", pancakeFactory.address);

  const PancakeRouter = await hre.ethers.getContractFactory("PancakeRouter");
  const pancakeRouter = await PancakeRouter.deploy(pancakeFactory.address, wBNB.address);
  await pancakeRouter.deployed();
  console.log("PancakeRouter deployed to:", pancakeRouter.address);

  console.log(await eobToken.balanceOf(owner.address));
  await eobToken["mint(uint256)"](ethers.BigNumber.from("100000000000000000000"));
	await eobToken["transfer(address,uint256)"](owner.address, ethers.BigNumber.from("100000000000000000000"));
	console.log(await eobToken.balanceOf(owner.address));
  await eobToken.approve(pancakeRouter.address, ethers.utils.parseEther("100.0"))

  await pancakeFactory.createPair(wBNB.address, eobToken.address);
  const pairAddress = await pancakeFactory.getPair(wBNB.address, eobToken.address);
  const PancakePair = await ethers.getContractFactory("PancakePair");
  const pair = await PancakePair.attach(pairAddress)
  console.log("Pair:", pairAddress);

  const _deadline = Date.now() + 1200;

  await pancakeRouter.addLiquidityETH(
    eobToken.address,
    ethers.BigNumber.from("100000000000000000000"),
    ethers.BigNumber.from("950000000000000000000"),
    ethers.BigNumber.from("1000000000000000000"),
    owner.address,
    _deadline,
    {value: ethers.utils.parseEther("1.0")},
  )
  console.log("LP:", await pair.balanceOf(owner.address));

  console.log("Pool Length:", await masterChef.poolLength());
  await masterChef.add(1, pairAddress, false);
  console.log("Pool Length:", await masterChef.poolLength());
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });