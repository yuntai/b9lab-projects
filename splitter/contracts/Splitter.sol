pragma solidity ^0.4.4;

contract Splitter {
  address public owner;

  struct WithdrawalStruct {
    uint balance;
    bool amountWithdrawn;
  }

  mapping(address => WithdrawalStruct) public withdrawalStructs;

  event LogSplitSent(address sender, address receiver0, address receiver1, uint
                    amount);
  event LogWithdrawalSent(address withdrawer, uint amount);

  function Splitter() {
    owner = msg.sender;
  }

  function split(address _receiver0, address _receiver1) 
    public
    payable
    returns(bool success)
  {

    if(_receiver0 == address(0) || _receiver1 == address(0)) {
      throw;
    }

    if(msg.value < 2) throw;

    var amount = msg.value/2;

    if(amount * 2 > msg.value) {
      withdrawalStructs[msg.sender].balance += 1
    }

    withdrawalAmount[_receiver0].balance += amount;
    withdrawalAmount[_receiver1].balance += amount;

    LogSplitSent(msg.sender, _receiver0, _receiver1, msg.value);

    return true
  }

  function kill() public {
    if(msg.sender != owner) throw;
    suicide(owner);
  }

  function withdraw() 
    public
    returns(bool success)
  {
    uint amountOwed = withdrawalStructs[msg.sender].balance -
      withdrawalStructs[msg.sender].amountWithdrawn;
    if(amountOwed == 0) throw;
    withdrawalStructs[msg.sender].amountWithdrawn += amountOwed;
    if(!msg.sender.send(amountOwed)) throw;
    LogWithdrawalSent(msg.sender, amountOwed);
    return true;
  }

  // `payable` keyword removed
  function() {}
}


// Rob's comment & response

// I've only had time to look at the Splitter. It's nice and concise. You're
// thinking about the rounding error and rejecting odd numbers. I can accept that,
// but it's not ideal.

//Your return at line 34 is clever but there is a problem. Either recipient can
// DoS the contract by deciding to throw. This is a common error.

//  You need to separate the concerns. As a guide, never talk to more than one
//untrusted contract at a time. Since the sender counts as 1, you should not try
//to forward the funds. Instead, just do some accounting and return true.

// Then, have the recipients claim their owed money with a withdraw() function.

//  There are some valuable lessons here in this simple example. You can expand
// the utility by making it so anyone can send to it, and specify two recipients.

//   Payable fallback is a mistake. There is no way to retrieve funds deposited in
// the contract that way, so funds would be marrooned in the contract - same as
// destroyed. Ouch!
