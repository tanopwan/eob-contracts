require("@nomiclabs/hardhat-waffle");

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  networks: {
    localhost: {
      gas: 24900000,
      blockGasLimit: 24900000,
      allowUnlimitedContractSize: true,
    },
  },
  solidity: {
    compilers: [
      {
        version: "0.5.16"
      },
      {
        version: "0.5.17"
      },
      {
        version: "0.6.6"
      },
      {
        version: "0.6.12"
      }
    ],
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000
      }
    }
  }
};
