//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.6;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
pragma experimental ABIEncoderV2;

struct User {
    address holder;
    uint stake;
    uint dateStaked;
    uint reward;
    bool isHolder;
}

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

    event createStakeEvent(User user);

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

    function InitiateRemoveStake(uint stake) public {
        require(isStakeHolder(msg.sender) == true, 'Not a stakeholder');
        User storage user = users[msg.sender];        
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
        
        user.stake = user.stake.sub(stake);
        if (user.stake == 0) 
            removeStakeHolder(msg.sender);
        _mint(msg.sender, stake);
    }

    function RemoveStake () public {
        LockedStake storage lockedStake = lockedStakes[msg.sender];
        require(lockedStake.locked == true, 'No stakes locked');
        uint amountUnstaked = lockedStake.stake;
        transfer(msg.sender, amountUnstaked);
        lockedStake.stake = lockedStake.stake.sub(amountUnstaked);
    }

    function stakeOf(address stakeHolder) public view returns (uint) {
        return users[stakeHolder].stake;
    }

    function totalStakes() public view returns (uint) {
        return _totalStakes;
    }

    function isStakeHolder (address _address)
        internal
        view
        returns (bool)
    {
        return users[_address].isHolder;
    }

    function removeStakeHolder(address stakeHolder) internal {
        require(isStakeHolder(msg.sender) == true, 'Not a stakeholder');
        users[stakeHolder].isHolder = false;
    }

    function rewardOf(address stakeHolder) external view returns (uint) {        
        require(isStakeHolder(msg.sender) == true, 'Not a stakeholder');
        return users[stakeHolder].reward;
    }

    function withdrawReward(uint amount) external {
        require(address(this).balance >= amount, 'Not enough tokens');
        User storage user  = users[msg.sender];
        user.reward = 0;
        _mint(msg.sender, user.reward);
    }

    function calculateRewardBasedOnApy(uint apy) public {
        require(isStakeHolder(msg.sender) == true, 'Not a stakeholder');
        User storage user = users[msg.sender];
        require(lockedStakes[msg.sender].locked == true, 'Stakes locked, cannot earn rewards');
        uint totalUserStake = stakeOf(msg.sender);
        require(totalUserStake < 0, 'stake is too low');
        uint apyPercentage = apy.div(100);
        uint reward = totalUserStake.mul(apyPercentage);
        uint finalAmount = reward / 365;
        user.reward.add(finalAmount);
    }
}
