const{developmentChains} = require("../helper-hardhat-config")
//const BASE_FEE = ethers.util.parseEther("0.25"); // 0.25 is the premium, it costs 0.25 LINK per request
const BASE_FEE = "250000000000000000" // 0.25 is this the premium in LINK?
const GAS_PRICE_LINK = 1e9 // link per gas. calculated value based on the gas price of the chain

// Chainlink Nodes pay the gas fees to give us randommess & do external execution
// So they price of request change based on the price of gas, we are the one actually will those gas
module.exports = async function({getNamedAccounts, deployments}) {
    const{deploy, log} = deployments;
    const{deployer} = await getNamedAccounts();
    const args = [BASE_FEE, GAS_PRICE_LINK];

    if(developmentChains.includes(network.name)){
        log("local network detected! Deploying mocks...");
        // deploy a mock vrfcoordinator...
        await deploy("VRFCoordinatorV2Mock", {
            from : deployer,
            log : true,
            args: args,
        })
        log("Mocks Deployed!");
        log("--------------------------------")

    }
}

module.exports.tags = ["all", "mocks"];
