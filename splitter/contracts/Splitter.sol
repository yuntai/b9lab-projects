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
    if(msg.value == 0) throw;
    var value = msg.value / 2;
    if((2*value) != msg.value) throw;
    bob.send(value);
    carol.send(value);
  }

  function kill() public {
    if(msg.sender != owner) throw;
    suicide(owner);
  }
}
