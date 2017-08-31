pragma solidity ^0.4.4;

import "./Stoppable.sol";

contract Remittance is Stoppable {
  address sender;
  address exchange;

  uint deadline;
  uint duration;
  uint amount;
  bytes32 passwordHashKey;

  bool feeClaimed = false;
  /* fee is filled when sender calls remitFund() and claimed by the
     owner with claimFee() */
  uint fee;

  // possible state transitions

  // Initial -> Funded -> Unlocked -> Paidout

  // with expiration coindtion
  // Initial -> Funded ->             Expired -> Refunded
  // Initial -> Funded -> Unlocked -> Expired -> Refunded

  enum State { Initial, Funded, Unlocked, Paidout, Refunded, Expired }
  State public state;
  modifier inState(State _state) { require(state == _state); _; }

  modifier checkExpiration() {
    if((state == State.Funded || state == State.Unlocked) && block.number > deadline) {
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
      bytes32 _passwordHashKey,
      uint _amount,
      uint _duration,
      uint _fee) 
  {
    require(_sender != address(0) && _exchange != address(0));
    require(amount > 0 && _duration > 0);

    sender = _sender;
    exchange = _exchange;
    passwordHashKey = _passwordHashKey;
    amount = _amount;
    duration = _duration;
    fee = _fee;
  }

  // fund contract
  function remitFund() 
    public 
    payable 
    onlySender
    inState(State.Initial)
    returns(bool success)
  {
    require(msg.value > amount + fee);
    state = State.Funded;
    // time ticks only after the contract is funded
    deadline = block.number + duration;
    return true; 
  }

  function unlockFund(bytes32 passwordExchange, bytes32 passwordBeneficiary) 
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
    revert();
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

  function claimFee()
    public
    onlyOwner
    returns(bool success)
  {
    require(state >= State.Funded);
    require(!feeClaimed);
    feeClaimed = true;
    owner.transfer(fee);
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
    selfdestruct(owner);
  }

	function () public {}
}
