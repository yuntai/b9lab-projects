pragma solidity ^0.4.6;

contract Campaign {
  
  address public owner;
  uint    public deadline;
  uint    public goal;
  uint    public fundsRaised;

  struct FunderStruct {
    uint    amountContributed;
    uint    amountRefunded;
  }

  mapping (address => FunderStruct) public funderStructs;

  event LogContribution(address sender, uint amount);
  event LogRefundSent(address funder,

  function Campaign(uint duration, uint _goal) {
    owner = msg.sender;
    deadline = block.number + duration;
    goal = _goal;
    isOpen = true;
  }

  function contributionAmount(address funder)
    public
    constant
    returns(uint amount)
  {
    if(msg.sender != owner) throw;
    uint funderCount = funderStructs.length;
    for(uint i=0; i<funderCount; i++) {
      if(funderStructs[i].funder == funder) {
        return funderStructs[i].amount;
      }
    }
    throw; // unknown funder
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
    payable
    returns(bool success)
  {
    if(msg.value == 0) throw;
    fundsRaised += msg.value;
    funderStructs[msg.sender].amount += msg.value;
    LogContribution(msg.sender, msg.value);
    return true;
  }


  function withdrawFunds() 
    public 
    returns(bool success) 
  {
    if(msg.sender != owner) throw;
    if(isSuccess()) throw;
    uint amount = this.balance;
    owner.send(amount);
    return true;
  }


  // after the campaing is finished the owner may not send refund
  // the owner can't send refund (lost private key)
  // funder.send may keep failing preventing the sends to be returned


  // rules
  // for loop => pushed to client
  // loopy logic out of the contract
  function requestRefund()
    public
    returns(bool success) 
  {
    uint amountOwed = funderStructs[msg.sender].amount -
      funderStructs[msg.sender].amountRefunded;
    if(amountOwed == 0) throw;
    if(!hasFailed()) throw;
    funderStructs[msg.sender].amountRefunded += amountOwed;
    if(!msg.sender.send(amountOwed)) throw;
    LogRefundSent(msg.sender, amountOwed);
    return true;
  }

}

