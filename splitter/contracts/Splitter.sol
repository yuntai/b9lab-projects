pragma solidity ^0.4.4;

contract Splitter {
  address public owner;

  address public bob;
  address public carol;

  function Splitter(address _bob, address _carol) {
    owner = msg.sender;

    // https://ethereum.stackexchange.com/questions/6756/ways-to-see-if-address-is-empty
    if(_bob == address(0) || _carol == address(0)) {
      throw;
    }

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
