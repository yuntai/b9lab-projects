pragma solidity ^0.4.0;

import "./Owned.sol";
import "./Stoppable.sol";

contract Campaign is Stoppable {
  address public sponsor;
  uint public deadline;
  uint public goal;
  uint public fundsRaised;
  uint public withdrawn;

  struct FunderStruct {
    uint amountContributed;
    uint amountRefunded;
  }

  mapping (address => FunderStruct) public funderStructs;

  modifier onlySponsor {
      require(msg.sender != sponsor);
      _;
  }
  event LogContribution(address sender, uint amount);
  event LogRefundSent(address funder, uint amount);
  event LogWithdrawal(address beneficiary, uint amount);

  function Campaign(address campaignSponsor, uint campaignDuration, uint campaignGoal) {
    sponsor = campaignSponsor;
    deadline = block.number + campaignDuration;
    goal = campaignGoal;
    running = true;
  }

  function isSuccess()
    public 
    constant
    returns(bool isIndeed)
  {
    return(fundsRaised >= goal);
  }

  function hasFailed()
    public
    constant
    returns(bool hasIndeed)
  {
    return(fundsRaised < goal && block.number > deadline);
  }

  function contribute()
    public
    onlyIfRunning
    payable
    returns(bool success)
  {
    require(msg.value != 0 && !isSuccess() && !hasFailed());

    fundsRaised += msg.value;
    funderStructs[msg.sender].amountContributed += msg.value;
    LogContribution(msg.sender, msg.value);
    return true;
  }

  function withdrawFunds()
    public
    onlySponsor
    onlyIfRunning
    returns(bool success)
  {
    require(isSuccess());
    // this.balance uncomfortable
    uint amount = fundsRaised - withdrawn;
    withdrawn += amount;
    owner.transfer(amount);
    LogWithdrawal(owner, amount);
    return true;
  }

  function requestRefund()
    public
    onlyIfRunning
    returns(bool success)
  {
    uint amountOwed = funderStructs[msg.sender].amountContributed -
      funderStructs[msg.sender].amountRefunded;
    require(amountOwed > 0 && hasFailed());

    funderStructs[msg.sender].amountRefunded += amountOwed;
    msg.sender.transfer(amountOwed);
    return true;
  }
}
