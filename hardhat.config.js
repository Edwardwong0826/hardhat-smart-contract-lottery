require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-verify");
require("@nomicfoundation/hardhat-ethers");
require("hardhat-deploy");
require("solidity-coverage");
require("hardhat-gas-reporter");
require("hardhat-contract-sizer");
require("dotenv").config();
const SEPOLIA_RPC_URL = process.env.SEPOLIA_RPC_URL;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY;
const COINMARKETCAP_API_KEY = process.env.COINMARKETCAP_API_KEY;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.24",

  // defaultNetwork: "hardhat" // this is fake default hardhat network running online, but is not the localhost like ganache
  // when we run - npx hardhat run scripts/deploy.js on default hardhat network, is only lives the duration on this command
  defaultNetwork: "hardhat",
  networks:{
    sepolia: {
        url: SEPOLIA_RPC_URL, // the testnet rpc url, get from alchemy
        accounts: [PRIVATE_KEY],
        chainId: 11155111, // put the testnet chainId
    },
    // this is localhost network, no need to specify account, because hardhat will automatically place in
    // npx hardhat node - run this command to launch localhost network, and copy the JSON-RPC URL put into here
    localhost: {
        url: "http://127.0.0.1:8545/",
        chainId : 31337, 
    },
    hardhat : {
        chainId: 31337,
        blockConfirmations: 1,
    },
  },

  namedAccounts: {
    deployer : {
      default : 0,
    },
    player: {
      default : 1,
    },
  },
};
