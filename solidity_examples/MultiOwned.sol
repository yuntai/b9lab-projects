// https://github.com/b9lab/both-needed/blob/master/contracts/MultiOwned.sol

pragma solidity ^0.4.5;

contract MultiOwned {
  mapping (address => bool) public owners;
  struct Confirmation {
    uint count;
    mapping (address => bool) confirmed;
  }

  mapping (bytes32 => Confirmation) public confirmations;

  event OnUnfinishedConfirmation(bytes32 key);

  function MultiOwned(address _owner2) {
    require(msg.sender != owner2 && _owner2 != address(0));
    owners[msg.sender] = true;
    owners[_owner2] = true;
  }

  modifier fromOwner {
    require(!owners[msg.sender]);
    _;
  }

  modifier isConfirmed {
    bytes32 key = hashData(msg.data);
