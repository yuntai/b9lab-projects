pragma solidity ^0.4.4;

contract Admined {
  address owner;
  address admin;

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  modifier onlyAdmin {
    require(msg.sender == admin);
    _;
  }

  function Admined(address _admin) {
    require(_admin != address(0));
    owner = msg.sender;
  }

  function changeAdmin(address newAdmin) 
    public
    onlyOwner
  {
    admin = newAdmin;
  }
}
