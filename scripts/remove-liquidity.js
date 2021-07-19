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

  const pancakeRouter = new ethers.Contract(routerAddr, pancakeRouterAbi, owner);
	const eobPair = new ethers.Contract(eobTokenAddr, pancakePairAbi, owner);

  const _deadline = Date.now() + 1200;

  await pancakeRouter.removeLiquidityETH(
    cakeToken.address,
    ethers.utils.parseEther("100000.0"),
    ethers.utils.parseEther("90000.0"),
    ethers.utils.parseEther("1.0"),
    owner.address,
    _deadline,
    {value: ethers.utils.parseEther("1.0")},
  )
  console.log("EOB-BNB LP:", (await cakePair.balanceOf(owner.address)).toString());
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });