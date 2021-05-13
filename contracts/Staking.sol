//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.6;
import 'hardhat/console.sol';
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
    mapping(address => User) public users;
    mapping(address => LockedStake) public lockedStakes;
    mapping(address => uint256) public balances;
    uint _totalStakes;
    uint APY = 50;
    uint WAIT_PERIOD = 1 minutes;
/*
initalizing amount of token supply in circulation
passing constructor value for erc 20 contract
*/
    constructor(
        address _owner,
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint totalSupply
    ) public ERC20(name, symbol, decimals, totalSupply) {
        _mint(_owner, totalSupply);
        _owner = msg.sender;  
        balances[msg.sender] = totalSupply;
    }

    // event createStakeEvent(User user);
/*
function creates a new struct object to track stakes and 
updats object if one exists already.
tokens are burnt to reduce total supply and create scarcity
 */
    function createStake(uint stake) public {
        transfer(msg.sender, stake);  
        _totalStakes = _totalStakes.add(stake);
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
            balances[msg.sender] = stake;
            // emit createStakeEvent(user);
       }else {
           User storage oldUser = users[msg.sender];
           oldUser.stake = oldUser.stake.add(stake);
           balances[msg.sender] = oldUser.stake;
       }     
    }
/* 
users can initate process to withdraw iinital investment without rewards  here
the funds will be locked for a period of time before finally being released
by calling RemoveStake ().
If user tries to unstake more of their inital investements, the timer will be reset
*/
    function InitiateRemoveStake(uint stake) public {
        require(isStakeHolder(msg.sender) == true, 'Not a stakeholder'); 
        require(balances[msg.sender] >= stake, 'Not enough tokens');
        require(stake > 0, 'stake too small');
        LockedStake storage lockedStake = lockedStakes[msg.sender];
        if(!lockedStake.locked) {
            LockedStake memory lockedStake = 
            LockedStake({
                stake: stake,
                dateLocked: now,
                locked: true
            });
            lockedStakes[msg.sender] = lockedStake;
            console.log('locked state',lockedStakes[msg.sender].locked);
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
        require(lockedStake.dateLocked + WAIT_PERIOD > now , 'waiting period has not been exceeded');
        uint amountUnstaked = lockedStake.stake;
        console.log('unstaked', amountUnstaked);
        transfer(msg.sender, amountUnstaked);
        balances[msg.sender] = balances[msg.sender].add(amountUnstaked);
        console.log('total stakes', _totalStakes);
        _totalStakes = _totalStakes.sub(amountUnstaked);
        lockedStake.stake = lockedStake.stake.sub(amountUnstaked);
        lockedStake.locked = false;
        _mint(msg.sender, amountUnstaked);
        console.log('current balance', balances[msg.sender]);
    }

    
/* 
function is called from an oracle once a day with a certain apy.
we then calculate ROI for that day based on users stake and current apy, that value 
is then added to users total reward
*/
    function calculateRewardBasedOnApy(uint apy) public {
        require(isStakeHolder(msg.sender) == true, 'Not a stakeholder');
        require(lockedStakes[msg.sender].locked == false, 'Stakes locked, cannot earn rewards');
        uint totalUserStake = stakeOf();
        console.log('totalUserStake', totalUserStake);
        require(totalUserStake > 0, 'stake is too low');
        uint apyPercentage = apy.div(100);
        console.log('apyPercentage', apyPercentage);
        uint reward = totalUserStake.mul(apyPercentage);
        uint roi = reward.div(365);
        User storage user = users[msg.sender];
        user.reward = user.reward.add(roi);
        console.log('user reward', user.reward);
        console.log('roi reward', roi);
    }

//returns current stake of a user
    function stakeOf() public view returns (uint) {
        return users[msg.sender].stake;
    }

//returns total number of stakes in the contract
    function totalStakes() public view returns (uint) {
        return _totalStakes;
    }

//returns users current balance
    function currentBalance() public view returns (uint) {
        return balances[msg.sender];
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
    function rewardOf() external view returns (uint) {        
        require(isStakeHolder(msg.sender) == true, 'Not a stakeholder');
        return users[msg.sender].reward;
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
}
