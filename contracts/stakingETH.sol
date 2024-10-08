// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

contract stakingEth {
   event EmergencyWithdraw(address indexed withdrawer, uint _amount);
   event WithdrawAll(address indexed withdrawer, uint _amount);
   event Staked( address indexed staker, uint _amount, uint durationinDays);
    event WithdrawToOwner (address indexed owner, uint _amount);
    struct userDetails {
        uint256 amountStaked;
        // not in sec just normal Days 1 for a Days 2 for 2 Days and so on ..
        uint256 numberOfDays;
        uint256 registrationTimestamp;
        bool isvalid;

    }
    // mapping og user to there detaila
    mapping(address => userDetails) stakes;
    uint256 public totalAmountStaked;
    // ER
    uint8 public fixedAPY;
    address immutable owner;
    // how long the day season will last
    uint256 durationInDays;

    // maximum amount of ethers that can be staking an account
    uint256 maxAmountStaked;
    
    uint256 startStake;

    constructor(
        //address _token,
        uint8 _fixedAPY,
        uint256 _durationInDays,
        uint256 _maxAmountStaked
    ) {
        owner = msg.sender;
        fixedAPY = _fixedAPY;
        durationInDays = _durationInDays;
        maxAmountStaked =_maxAmountStaked;
        startStake  = block.timestamp;

    }

    function getAmountStakebyUser(address _user)
        external
        view
        returns (uint256)
    {
       return  stakes[_user].amountStaked;
    }

    function getMyStakedAmount() external view returns (uint256) {
        return stakes[msg.sender].amountStaked;
    }


    function stake(uint256 _days) external  payable  {
       require(msg.sender != address(0), "zero address detected");
       require(msg.value > 0 ," you have  send value");
       require(msg.value <= maxAmountStaked ," you have  send value");
      
       require( _checkDuration(),"you can't stake again duration past");

         totalAmountStaked = totalAmountStaked +  msg.value;
        stakes[msg.sender] = userDetails(msg.value,_days,block.timestamp,true);
        emit Staked(msg.sender, msg.value, _days);

    }

    // user will not get any reward for the eth withraw
    function emergencyWithdraw(uint256 _amount) external {
        require(msg.sender != address(0), "zero address detected");
        // this also check that the user has so amount stake
        require(stakes[msg.sender].amountStaked >= _amount, "you do not have the funds ");
        require(stakes[msg.sender].isvalid, "user cannot withdraw");
        
        stakes[msg.sender].amountStaked = stakes[msg.sender].amountStaked - _amount;
        if (stakes[msg.sender].amountStaked == 0){
            stakes[msg.sender].isvalid = false;
        }
        totalAmountStaked = totalAmountStaked - _amount;
        (bool success,) = msg.sender.call{value : _amount}("");
        require(success,"something went wrong");

        emit EmergencyWithdraw(msg.sender,_amount );
    }

    function withdraw() external {
        require(msg.sender != address(0), "zero address detected");
        // this also check that the user has so amount stake
        require(stakes[msg.sender].isvalid, "user cannot withdraw");

        require(block.timestamp >= stakes[msg.sender].registrationTimestamp + stakes[msg.sender].numberOfDays * 1 days,"chill can't withdraw yet");

   uint256 amountToPay = _calculateReward(stakes[msg.sender].numberOfDays) + stakes[msg.sender].amountStaked;

          totalAmountStaked = totalAmountStaked -  stakes[msg.sender].amountStaked;

         stakes[msg.sender].amountStaked = 0;

        stakes[msg.sender].isvalid = false;
      
        (bool success,) = msg.sender.call{value : amountToPay}("");
        require(success,"something went wrong");
        emit WithdrawAll(msg.sender,amountToPay );

    }

    function _calculateReward(uint256 _days) private view returns (uint256) {
       return (stakes[msg.sender].amountStaked*fixedAPY*_days) / 36500  ; //365 *100
    }
// this function with only withdraw to owner 1 year after the staking duration as ended
     function withdrawToOwner () external {
        require(msg.sender == owner, "you are not owner");
        uint256 oneYearafter = (1 days *365) + startStake + durationInDays * 1 days;
        require(block.timestamp > oneYearafter, "it is not yet time to withdraw to you ");
        
        (bool success,) = owner.call{value : address(this).balance }("");
        require(success,"something went wrong");
        emit WithdrawToOwner(owner,address(this).balance );

    }
    // return true if the staking period as not passed
    function _checkDuration() private view returns(bool passed){
        uint256 durationInsec = startStake + durationInDays * 1 days;
        if (durationInsec <= block.timestamp){
            return true;
        }
        return false;
    }
}
