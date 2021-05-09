const fs = require('fs');

async function main () {
    const [deployer] = await ethers.getSigners();
    console.log(`Deploying contracts with the account: ${deployer.address}`);

    const balance = await deployer.getBalance();
    console.log(`Account balance: ${balance.toString()}`);

    const Staking = await ethers.getContractFactory('Staking');
    const staking = await Staking.deploy( deployer.address, 'Staking Contract Token', 'SCT', 18, 100000000);
    // console.log(staking, 'staking issue');
    console.log(`Staking address: ${staking.address}`);

    const data = {
        address: staking.address,
        abi: JSON.parse(staking.interface.format('json'))
    };
    // fs.writeFileSync('frontend/src/Token.json', JSON.stringify(data));
}
main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });