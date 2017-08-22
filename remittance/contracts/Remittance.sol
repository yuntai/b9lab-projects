pragma solidity ^0.4.4;

import "./Owned.sol";

contract Remittance is Owned {
  address sender;
  address exchange;

  uint deadline;
  uint duration;
  uint amount;
  string passwordHashKey;

  // possible state transitions

  // Initial -> Funded -> Unlocked -> Paidout

  // with expiration coindtion
  // Initial -> Funded ->             Expired -> Refunded
  // Initial -> Funded -> Unlocked -> Expired -> Refunded

  enum State { Initial, Funded, Unlocked, Paidout, Refunded, Expired }
  State public state;
  modifier inState(State _state) { require(state == _state); _; }

  modifier checkExpiration() {
    if((state == State.Funded || state == State.Unlcoked) && block.number > deadline) {
      state = State.Expired; 
    }
    _;
  }

  modifier onlySender() { require(msg.sender == sender); _; }
  modifier onlyExchange() { require(msg.sender == exchange); _; }

  event LogRefundSent(address _sender, uint _amount);

  function Remittance(
      address _sender,
      address _exchange, 
      string _passwordHashKey,
      uint _amount,
      uint _duration) 
  {
    require(_sender != address(0) && _exchange != address(0));
    require(bytes(_passwordHashKey).length > 0);
    require(msg.value > 0 && amount > 0 && msg.value > _amount && _duration > 0);

    sender = _sender;
    exchange = _exchange;
    passwordHashKey = _passwordHashKey;
    amount = _amount;
    duration = _duration;
  }

  // fund contract
  function remitFund() 
    public 
    payable 
    onlySender
    inState(State.Initial)
    returns(bool success)
  {
    require(msg.value > amount);
    state = State.Funded;
    // time ticks only after the contract is funded
    deadline = block.number + duration;
    return true; 
  }

  function unlockFund(string passwordExchange, string passwordBeneficiary) 
    public
    onlyExchange
    checkExpiration
    inState(State.Funded)
    returns(bool success)
  {
    if(keccak256(keccak256(passwordExchange), keccak256(passwordBeneficiary)) == passwordHashKey) {
      state = State.Unlocked;
      return true;
    }
    return false;
  }

  function claimFund()
    public
    onlyExchange
    checkExpiration
    inState(State.Unlocked)
    returns(bool success)
  {
    state = State.Paidout; // should revert to Unlcoked when transfer throws
    exchange.transfer(amount);
    return true;
  }

  function refund()
    public
    onlySender
    checkExpiration
    inState(State.Expired)
    returns(bool success)
  {
    state = State.Refunded;
    sender.transfer(this.balance);
    return true;
  }

  function kill()
    public
    onlyOwner
  {
    require(state == State.Initial || state == State.Paidout || state == State.Refunded);
    selfdestruct(sender);
  }

	function () public {}
}
