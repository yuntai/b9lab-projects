pragma solidity ^0.4.6;

contract Owned {
  address public owner;

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function Owned() {
    owner = msg.sender;
  }
}
