const {expect, assert} = require('chai');
const {ethers} = require('hardhat');
// const BigNumber = require('bignumber.js');

describe('Staking contract', () => {
    let Stake, stake, owner, user, addr2;
    // const tokens = BigNumber(10).pow(18).multipliedBy(1000);
    
    beforeEach(async () => {
        Stake = await ethers.getContractFactory('Staking');

        [owner, user, addr2, _] = await ethers.getSigners();
        // console.log(Stake, "staking contract instance")
        stake = await Stake.deploy(owner.address, 1000000, "Staking Contract Token", "SCT", 18, 100000000 );

        // console.log(stake, "lol")
    });

    describe('Staking', () => {
        it('should create a stake', async () => {
            await stake.transfer(user.address, 5);
            await stake.createStake(2);

            expect(await stake.balanceOf(user.address), 5);
            expect(await stake.stakeOf(user.address), 2);
            expect(await stake.totalStakes(), 2);
        });

        


    });
});