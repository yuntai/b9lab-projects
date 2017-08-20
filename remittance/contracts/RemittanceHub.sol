pragma solidity ^0.4.4;

contract RemittanceHub {
  address public owner;
	uint		public durationLimit;
  uint    public smallCut;

  struct Remittance {
    address sender;
    address exchangeAddress;
    address receiver;
    uint sendAmount;
    uint deadline;
    uint amount;
    string pwHash1;
    string pwHash2;
    bool isPaidout;
  }

  mapping(string => Remittance) public remittances;

  function RemittanceHub(uint _durationLimit, uint _smallCut) {
    owner = msg.sender;
    durationLimit = _durationLimit;
    smallCut = _smallCut;
  }

  function addRemittance(address _exchangeAddress, address _receiver, 
                         string _pwHash1, string _pwHash2, uint _duration)
    public
    payable
    returns (bool success) 
  {
    // check deadline limit
    if(_duration > durationLimit) throw;

    // need to deposit some amount 
    if(msg.value <= smallCut) throw;

    bytes32 key = keccak256(_pwHash1, _pwHash2);

    remittances[key].sender = msg.sender;
    remittances[key].exchangeAddress = _exchangeAddress;
    remittances[key].receiver = _receiver;
    remittances[key].deadline = block.number + _duration;
    remittances[key].isPaidout = false;
    remittances[key].amount = msg.value - smallCut;

    return true;
  }

  function stringsEqual(string _a, string _b) internal returns (bool) {
    bytes memory a = bytes(_a);
    bytes memory b = bytes(_b);
    return a == b;
  }

  function remit(address sender, address receiver, string pwHash1, string
                pwHash2)
  public
  returns(bool success)
  {
    uint remittanceCount = remittanceStructs.length;
    for(uint i=0; i<remittanceCount; i++) {
      if( remittanceStructs[i].exchangeAddress == msg.sender &&
          remittanceStructs[i].sender == sender &&
          remittanceStructs[i].receiver == receiver &&
          bytes(remittanceStructs[i].pwHash)  == keccak256(pw) &&
          remittanceStructs[i].deadline < block.number &&
          remittanceStructs[i].isPaidout == false 
        ) {
          if(msg.sender.send(remittanceStructs[i].amount)) {
            remittanceStructs[i].isPaidout = true;
          }
      }
    }
    throw;
  }

  function claim(address exchangeAddress, address receiver, string pw)
  public
  returns(bool success)
  {
    uint remittanceCount = remittanceStructs.length;
    for(uint i=0; i<remittanceCount; i++) {
      if( remittanceStructs[i].exchangeAddress == exchangeAddress &&
          remittanceStructs[i].sender == msg.sender &&
          remittanceStructs[i].receiver == receiver &&
          bytes(remittanceStructs[i].pwHash)  == keccak256(pw) &&
          remittanceStructs[i].deadline >= block.number &&
          remittanceStructs[i].isPaidout == false 
        ) {
          if(msg.sender.send(remittanceStructs[i].amount)) {
            remittanceStructs[i].isPaidout = true;
          }
      }
    }
    throw;
  }

	function killMe() returns (bool) {
  	if (msg.sender == owner) {
      uint remittanceCount = remittanceStructs.length;
      for(uint i=0; i<remittanceCount; i++) {
        if(remittanceStructs[i].isPaidout == false) {
          if(msg.sender.send(remittanceStructs[i].amount)) {
            remittanceStructs[i].isPaidout = true;
          }
        }
      }
    	suicide(owner);
      return true;
    }
	}

	function () payable {}
}
