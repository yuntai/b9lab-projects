pragma solidity ^0.4.4;

contract Remittance is Owned {
  address sender;
  address exchange;

  uint deadline;
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
    if((state == Funded || staet == Unlcoked) && block.number > deadline) {
      state = Expired; 
    }
    _;
  }

  event LogRemittance(address sender, uint amount);
  event LogRefundSent(address sender, uint amount);

  function Remittance(
      address _sender,
      address _exchange, 
      string _passwordHashKey,
      uint amount,
      uint _duration) 
  {
    require(_sender != address(0) && _exchange != address(0) 
              && _receiver != address(0));
    require(bytes(_passwordHashKey).length > 0)
    require(msg.value > 0 && amount > 0 && msg.value > amount && _duration > 0);

    sender = _sender;
    exchange = _exchange;
    receiver = _receiver;
    passwordHashKey = _passwordHashKey;
  }

  // fund contract
  function remitFund() 
    public 
    payable 
    onlySender
    inState(Initial)
    returns(bool success)
  {
    require(msg.value > amount);
    state = Funded;
    // time ticks only after the contract is funded
    deadline = block.number + _duration;
    return true; 
  }

  function unlockFund(string passwordExchange, string passwordBeneficiary) 
    public
    onlyExchange
    checkExpiration
    inState(Funded)
    returns(bool success)
  {
    if(keccak256(keccak256(passwordExchange), keccak256(passwordBeneficiary)) == passwordHashKey) {
      state = Unlocked;
      return true;
    }
    return false;
  }

  function claimFund()
    public
    onlyExchange
    checkExpiration
    inState(Unlocked)
    returns(bool success)
  {
    state = Paidout; // should revert to Unlcoked when transfer throws
    exchange.transfer(amount);
    return true;
  }

  function refund()
    public
    onlySender
    checkExpiration
    inState(Expired)
    returns(bool success)
  {
    state = Refunded;
    sender.transfer(this.balance);
    return true;
  }

  function kill()
    public
    onlyOwner
  {
    require(state == Initial || state == Paidout || state == Refunded);
    selfdestruct(sender);
  }

	function () public {}
}
