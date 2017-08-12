pragma solidity ^0.4.4;

contract Splitter {
  address public owner;

  address public bob;
  address public carol;

  function Splitter(address _bob, address _carol) {
    owner = msg.sender;

    bob = _bob;
    carol = _carol;
  }

  function split() 
    public
    payable
    returns(bool success)
  {
    if(msg.value < 2) throw;
    var amount = msg.value/2;
    
    if(amount * 2 > msg.value) {
      if(!msg.sender.send(1)) {
        return false;
      }
    }
    return bob.send(amount) && carol.send(amount);
  }

  function kill() public {
    if(msg.sender != owner) throw;
    suicide(owner);
  }
}
