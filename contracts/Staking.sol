//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.6;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
pragma experimental ABIEncoderV2;

/* 
struct contains all stakeholder details
*/
struct User {
    address holder;
    uint stake;
    uint dateStaked;
    uint reward;
    bool isHolder;
}
/* 
struct stores amount of users initial investment to be withdrawn 
*/
struct LockedStake {
    uint stake;
    uint dateLocked;
    bool locked;
}

contract Staking is ERC20, Ownable {
    mapping(address => User) internal users;
    mapping(address => LockedStake) internal lockedStakes;
    uint _totalStakes;
    uint APY = 50;
    uint WAIT_PERIOD = 2 days;
/*
initalizing amount of token supply in circulation
passing constructor value for erc 20 contract
*/
    constructor(
        address _owner,
        uint _supply,
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint totalSupply
    ) public ERC20(name, symbol, decimals, totalSupply) {
        _mint(_owner, _supply);
    }

    // event createStakeEvent(User user);
/*
function creates a new struct object to track stakes and 
updats object if one exists already.
tokens are burnt to reduce total supply and create scarcity
 */
    function createStake(uint stake) public {
        _burn(msg.sender, stake);  
        _totalStakes.add(stake);
       if(!isStakeHolder(msg.sender)){
           User memory user =
            User({
                holder: msg.sender,
                stake: stake,
                dateStaked: now,
                reward: 0,
                isHolder: true
            });
            users[msg.sender] = user;
            // emit createStakeEvent(user);
       }else {
           User storage oldUser = users[msg.sender];
           oldUser.stake = oldUser.stake.add(stake);
       }     
    }
/* 
users can initate process to withdraw iinital investment without rewards  here
the funds will be locked for a period of time before finally being released
by calling RemoveStake ().
If user tries to unstake more of their inital investements, the timer will be reset
once a user has 0 stakes.
*/
    function InitiateRemoveStake(uint stake) public {
        require(isStakeHolder(msg.sender) == true, 'Not a stakeholder');    
        require(address(this).balance >= stake, 'Not enough tokens');
   
        LockedStake storage lockedStake = lockedStakes[msg.sender];
        if(!lockedStake.locked) {
            LockedStake memory lockedStake = 
            LockedStake({
                stake: stake,
                dateLocked: now,
                locked: true
            });
            lockedStakes[msg.sender] = lockedStake;
        } else {
            lockedStake.stake = lockedStake.stake.add(stake);
            lockedStake.dateLocked = lockedStake.dateLocked = now;
        }        
        
        User storage user = users[msg.sender]; 
        user.stake = user.stake.sub(stake);
    }
/* 
locked stakes are transfered to users address
total stakes is also reduced
*/
    function RemoveStake () public {
        LockedStake storage lockedStake = lockedStakes[msg.sender];
        require(lockedStake.locked == true, 'No stakes locked');
        require(lockedStake.dateLocked > WAIT_PERIOD, 'waiting period has not been exceeded');
        uint amountUnstaked = lockedStake.stake;
        transfer(msg.sender, amountUnstaked);
        _totalStakes.sub(amountUnstaked);
        lockedStake.stake = lockedStake.stake.sub(amountUnstaked);
        lockedStake.locked = false;
        _mint(msg.sender, amountUnstaked);
    }

//returns current stake of a user
    function stakeOf(address stakeHolder) public view returns (uint) {
        return users[stakeHolder].stake;
    }

//returns total number of stakes in the contract
    function totalStakes() public view returns (uint) {
        return _totalStakes;
    }

//check if a user is a holder
    function isStakeHolder (address _address)
        internal
        view
        returns (bool)
    {
        return users[_address].isHolder;
    }

//returns how much rewards a user has made
    function rewardOf(address stakeHolder) external view returns (uint) {        
        require(isStakeHolder(msg.sender) == true, 'Not a stakeholder');
        return users[stakeHolder].reward;
    }

/*
user can withdraw reward gained here
once reward amount is available, it is transfered to users address
*/
    function withdrawReward(uint amount) external {      
        require(isStakeHolder(msg.sender) == true, 'Not a stakeholder');        
        User storage user  = users[msg.sender];
        require(user.reward >= amount, 'Not enough tokens');
        transfer(msg.sender, amount);
        user.reward = user.reward.sub(amount);
    }
/* 
function is called from an oracle once a day with a certain apy.
we then calculate ROI for that day based on users stake and current apy, that value 
is then added to users total reward
*/
    function calculateRewardBasedOnApy(uint apy) public {
        require(isStakeHolder(msg.sender) == true, 'Not a stakeholder');
        require(lockedStakes[msg.sender].locked == true, 'Stakes locked, cannot earn rewards');
        uint totalUserStake = stakeOf(msg.sender);
        require(totalUserStake < 0, 'stake is too low');
        uint apyPercentage = apy.div(100);
        uint reward = totalUserStake.mul(apyPercentage);
        uint roi = reward / 365;
        User storage user = users[msg.sender];
        user.reward.add(roi);
    }
}
