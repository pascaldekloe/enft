require("@nomiclabs/hardhat-waffle");

module.exports = {
  solidity: {
    version: "0.8.14",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000
      }
    }
  }
};
