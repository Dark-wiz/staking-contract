const {expect, assert} = require('chai');
const {ethers} = require('hardhat');
// const BigNumber = require('bignumber.js');

const waitTime = (minutes) => new Promise(resolve => setTimeout(resolve, minutes * 60 * 1000));

describe('Staking contract', () => {
    let Stake, stake, owner, user, addr2;
    // const tokens = BigNumber(10).pow(18).multipliedBy(1000);
    
    beforeEach(async () => {
        Stake = await ethers.getContractFactory('Staking');

        [owner, user, addr2, _] = await ethers.getSigners();
        // console.log(Stake, "staking contract instance")
        stake = await Stake.deploy(owner.address, "Staking Contract Token", "SCT", 18, 100000000 );
        await stake.transfer(user.address, 10);
        await stake.createStake(5);
        
    });

    describe('Deployment', () => {
        it('should set owner address', async () => {
            expect(await stake.owner()).to.equal(owner.address);
        });
    });

    describe('Staking', () => {
        it('should create a stake', async () => {
            
            await stake.transfer(addr2.address, 10);
            await stake.createStake(5);
            expect(await stake.currentBalance()).to.be.equal(10);
            expect(await stake.stakeOf()).to.be.equal(10);
            expect(await stake.totalStakes()).to.be.equal(10);
        });

        it('should lock stake', async () => {
            await stake.InitiateRemoveStake(2);
            expect(await stake.stakeOf()).to.equal(3);

            await expect(stake.InitiateRemoveStake(0)).to.be.revertedWith('stake too small');
        });


        it('should transfer locked stake', async () => {
            await stake.InitiateRemoveStake(2);
            waitTime(2);
            await stake.RemoveStake();
            expect(await stake.currentBalance()).to.be.equal(7);
        });



    });
});