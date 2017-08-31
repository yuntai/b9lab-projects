pragma solidity ^0.4.4;

import "./Remittance.sol";
import "./Stoppable.sol";

/*
Alice parepaes two password password1 & password2
and hash them = h1 = H(passsword1) h2 = H(password2)

(createing remittance contract)
Alice --- createRemittance(h1, h2, exchange) ---> RemittanceHub
      <------- aRemittance ------

(Alice fund the contract, timer starts)
Alice ---- fund() ----> aRemittance

(off-chain)
Alice ---- aRemittance, password1 ---> exchange
Alice ---- password2              ---> bob

Upon confirming aRemittance funded, exchange arranges the meeting with bob

exchange ---> claim(password1, password2) ----> aRemittance 
(fund unlocked for exchange)

(pull fund)
exchange ---> claimFund()         ----> aRemittance
         <-------- ether           -----

*/

contract RemittanceHub is Stoppable {

  uint maxDuration; // maximum duration allowed
  uint passwordDuration; 
  uint fee;         // fee for the hub

  address[] public remittances;
  mapping(address => bool) remittanceExists;

  event LogNewRemittance(address _sender, address _remittance, address _exchange, uint _duration, uint _amount);

  struct PasswordStruct {
    bool exists;
    uint timeout;
  }

  mapping(string => PasswordStruct) passwordExist;

  function isPasswordReused(string passwordHash)
    public
    constant
    returns(bool exists)
  {
    if(passwordHashSeen[passwordHash].exists &&
       passwordHashSeen[passwordHash].timeout > block.number)
      passwordHashSeen[passwordHash].exists = false;

    return passwordHashSeen[passwordHash].exists;
  }

  function recordPasswordHash(string passwordHash)
    public
  {
    passwordHashSeen[passwordHash].exists = true;
    passwordHashSeen[passwordHash].timeout = block.number + passwordDuration;
  }

  modifier onlyIfRemittance(address remittance) {
    require(remittanceExists[remittance]);
    _;
  }

  function RemittanceHub(uint _fee, uint _maxDuration, uint _passwordDuration) {
    require(_maxDuration > 0 && _fee > 0 && _passwordDuration > 0);

    fee = _fee;
    maxDuration = _maxDuration;
    passwordDuration = _passwordDuration;
  }

  function getRemittanceCount()
    public
    constant
    returns(uint remittanceCount)
  {
    return remittances.length;
  }

  // Alice create two password (password1, password2)
  // create two hashes H(password1) and H(password2) and submit with
  // createRemittance() request
  // password1 and password2 are sent to exchange shop and reciever,
  // respecitvely.
  function createRemittance(uint amount, 
                            uint duration, 
                            address exchangeAddress, 
                            string passwordHashKey1,
                            string passwordHashKey2)
    public
    onlyIfRunning
    returns(address remittanceContract)
  {
    require(exchangeAddress != address(0));
    require(bytes(passwordHashKey1).length > 0);
    require(bytes(passwordHashKey2).length > 0);
    require(duration < maxDuration);
    require(amount > 0);
    require(!isPasswordHashSeen(passwordHashKey1));
    require(!isPasswordHashSeen(passwordHashKey2));

    recordPasswordHash(passwordHashKey1);
    recordPasswordHash(passwordHashKey2);

    bytes32 passwordHashKey = keccak256(passwordHashKey1, passwordHashKey2);

    // contract unfunded 
    Remittance trustedRemittance = new Remittance(
      msg.sender, 
      exchangeAddress,
      passwordHashKey,
      amount,
      duration,
      fee);

    remittances.push(trustedRemittance);
    remittanceExists[trustedRemittance] = true;
    LogNewRemittance(msg.sender, trustedRemittance, exchangeAddress, duration, amount);
    return trustedRemittance;
  }

  function stopRemittance(address remittance)
    public
    onlyOwner
    onlyIfRemittance(remittance)
    returns(bool success)
  {
    Remittance trustedRemittance = Remittance(remittance);
    return(trustedRemittance.runSwitch(false));
  }

  function startRemittance(address remittance)
    public
    onlyOwner
    onlyIfRemittance(remittance)
    returns(bool success)
  {
    Remittance trustedRemittance = Remittance(remittance);
    return(trustedRemittance.runSwitch(true));
  }

	function killMe() 
    public
    onlyOwner
    returns (bool) 
  {
    selfdestruct(owner);
	}

	function () {}
}
