//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.3;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

struct stakeholder {
    address holder;
    uint stake;
    uint dateStaked;
}

contract Staking is ERC20, Ownable {
    address[] internal stakeHolders;

    mapping(address => uint) internal stakes;

    mapping(address => uint) internal rewards;

    constructor(address _owner, uint _supply) {
        _mint(_owner, _supply);
    }

    function createStake(uint _stake) public {
        _burn(msg.sender, _stake);
        if(stakes[msg.sender] == 0)
            addStakeHolder(msg.sender);
        stakes[msg.sender] = stakes[msg.sender].add(_stake);
    }

    function removeStake(uint _stake) public {
        stakes[msg.sender] = stakes[msg.sender].sub(_stake);
        if(stakes[msg.sender] == 0) 
            removeStakeHolder(msg.sender);
        _mint(msg.sender, _stake);
    }

    function stakeOf(address _stakeHolder) public view returns(uint) {
        return stakes[_stakeHolder];
    }

    function totalStakes() public view returns(uint) {
        uint _totalStakes = 0;
        for (uint s = 0; s < stakeHolders.length; s++) {
            _totalStakes = _totalStakes.add(stakes[stakeHolders[s]]);
        }
        return _totalStakes;
    }

    function isStakeHolder(address _address) public view returns(bool, uint) {
        for (uint s = 0; s < stakeHolders.length; s++) {
            if(_address == stakeHolders[s])
                return (true, s);
        }
        return (false, 0);        
    }

    function addStakeHolder(address _stakeHolder) public {
        (bool _isStakeHolder, ) = isStakeHolder(_stakeHolder); //what???
        if(!_stakeHolder)  stakeHolders.push(_stakeHolder);
    }

    function removeStakeHolder(address _stakeHolder) public {
        (bool _isStakeHolder, uint s) = isStakeHolder(_stakeHolder);
        if(_isStakeHolder) { 
            stakeHolders[s] = stakeHolders[stakeHolders.length - 1];
            stakeHolders.pop();
        }
    }

    function rewardOf(address _stakeHolder) public view returns(uint) {
        return rewards[_stakeHolder];
    }

    function addReward(address _stakeHolder) public {
        
    }
    

    function withdrawReward() public {
        uint reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        _mint(msg.sender, reward);
    }

}
