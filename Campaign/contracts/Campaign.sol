pragma solidity ^0.4.6;

contract Campaign {
  
  address public owner;
  uint    public deadline;
  uint    public goal;
  uint    public fundsRaised;
  bool    public isOpen;

  struct FunderStruct {
    address funder;
    uint    amount;
  }

  FunderStruct[] public funderStructs;

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
    FunderStruct memory newFunder;
    newFunder.funder = msg.sender;
    newFunder.amount = msg.value;
    funderStructs.push(newFunder);
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

  function sendRefunds() 
    public 
    returns(bool success) 
  {
    if(msg.sender != owner) throw;
    if(!hasFailed()) throw;

    uint funderCount = funderStructs.length;
    for(uint i=0; i<funderCount; i++) {
      funderStructs[i].funder.send(funderStructs[i].amount);
    }
    return true;
  }
}

