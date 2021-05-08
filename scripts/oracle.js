const { ethers } = require("ethers");
const { artifacts } = require("hardhat");

const Staking = artifacts.require('Staking.sol');
const CALL_INTERVAL = 86400000;

module.exports = async calculateRoi => {
    const [_, reporter] = await web3.eth.getAccounts();
    const oracle = await Staking.deployed();
    
    while(true) {
        await oracle.calculateRewardBasedOnApy(
            {from: reporter}
        )
        await new Promise((resolve, _) => setTimeout(resolve, CALL_INTERVAL));
    }
    calculateRoi();
}