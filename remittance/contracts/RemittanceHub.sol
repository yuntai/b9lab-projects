pragma solidity ^0.4.4;

import "./Remittance.sol";


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

  address[] public remitances;
  mapping(address => bool) remitanceExists;

  struct PasswordSeenStruct {
    bool isSeen;
    uint timeout;
  };

  mapping(string => PasswordSeenStruct) passwordHashSeen;

  function isPasswordHashSeen(string passwordHash)
    public
    constant
    returns(bool isSeen)
  {
    if(passwordHashSeen[passwordHash].isSeen &&
       passwordHashSeen[passwordHash].timeout > block.number)
      passwordHashSeen[passwordHash].isSeen = false;

    return passwordHashSeen[passwordHash].isSeen = false;
  }

  function recordPasswordHash(string passwordHash)
    public
    returns(bool success)
  {
    passwordHashSeen[passwordHash].isSeen = true;
    passwordHashSeen[passwordHash].timeout = block.number + passwordDuration;
  }

  modifier onlyIfRemittance(address remittance) {
    require(remitanceExists[remittance]);
    _;
  }

  function RemittanceHub(_maxDuration, _fee, _passwordDuration) {
    require(_maxDuration > 0 && _fee > 0);

    maxDuration = _maxDuration;
    fee = _fee;
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
    require(passwordHashKey1 != string(0));
    require(passwordHashKey2 != string(0));
    require(duration < maxDuration);
    require(amount > 0 && msg.value > fee);
    require(!isPasswordHashSeen(passwordHashKey1);
    require(!isPasswordHashSeen(passwordHashKey2);

    recordPassword(passwordHashKey1);
    recordPassword(passwordHashKey2);

    passwordHashKey = keccak256(passwordHashKey1, passwordHashKey2);

    // contract unfunded 
    Remittance trustedRemittance = new Remittance(
      msg.sender, 
      exchangeAddress,
      passwordHashKey,
      amount,
      duration);

    remittances[passwordHashKey] = trustedRemittance;
    remitanceExists[trustedRemittance] = true;
    LogNewRemittance(msg.sender, trustedRemittance, exchangeAddress, duration, amount);
    return trustedRemittance;
  }

  function stopRemittance(address remitance)
    public
    onlyOwner
    onlyIfRemittance(remittance)
    returns(bool success)
  {
    Remittance trustedRemittance = Remittance(remittance);
    return(trustedRemittance.runSwitch(false));
  }

  function startRemittance(address remitance)
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
