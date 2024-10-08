const { deployments, network, ethers } = require("hardhat");
const { developmentChains, networkConfig } = require("../helper-hardhat-config");
const { verify } = require("../helper-hardhat-config");

const VRF_SUB_FUND_AMOUNT = ethers.parseEther("0.2");

module.exports = async function({getNamedAccounts, deployment}) {
    const{deploy, log} = deployments;
    const{deployer} = await getNamedAccounts();
    const chainId = network.config.chainId;
    let vrfCoordinatorV2Address, subscriptionId;

    if(developmentChains.includes(network.name)){
        // ethers.getContract is verison 4
        // ethers.getContractAt is version 6
        const VRFCoordinatorV2Mock = await ethers.getContractAt("VRFCoordinatorV2Mock")
        vrfCoordinatorV2Address = VRFCoordinatorV2Mock.address;

        const transactionResponse = await VRFCoordinatorV2Mock.createSubscription();
        const transactionReceipt = await transactionResponse.wait(1);
        subscriptionId = transactionReceipt.event[0].args.subId;

        // Fund the subscription
        // Usually need the link token on a real network
        await VRFCoordinatorV2Mock.fundSubcription(subscriptionId, VRF_SUB_FUND_AMOUNT);



    } else {
        vrfCoordinatorV2Address = networkConfig[chainId]["vrfCoordinatorV2"];
        subscriptionId = networkConfig[chainId]["subscriptionId"];
    }

    const entranceFee = networkConfig[chainId]["entranceFee"];
    const gasLane = networkConfig[chainId]["gasLane"];
    const callBackGasLimit = networkConfig[chainId]["callBackGasLimit"];
    const interval = networkConfig[chainId]["interval"];

    const args = [vrfCoordinatorV2Address, entranceFee, gasLane,
         subscriptionId, callBackGasLimit, interval];

    const raffle = await deploy("Raffle", {
        from : deployer,
        args: args,
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1,
    })

        // Verify the deployment
        if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
            log("Verifying...");
            await verify(raffle.address, args);
        }

        log("----------------------------------------------")

}

module.exports.tags = ["all", "raffle"];
