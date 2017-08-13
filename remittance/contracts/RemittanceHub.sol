pragma solidity ^0.4.4;

contract RemittanceHub {
  address public owner;
	uint		public durationLimit;
  uint    public smallCut;

  struct RemittanceStruct {
    address sender;
    address exchangeAddress;
    address receiver;
    uint sendAmount;
    uint deadline;
    uint amount;
    string pwHash;
    bool isPaidout;
  }

  RemittanceStruct[] public remittanceStructs;

  function RemittanceHub(uint _durationLimit, uint _smallCut) {
    owner = msg.sender;
    durationLimit = _durationLimit;
    smallCut = _smallCut;
  }

  function addRemittance(address _exchangeAddress, address _receiver, 
                         string _pwHash, uint _duration)
    public
    payable
    returns (bool success) 
  {
    // check deadline limit
    if(_duration > durationLimit) throw;
    // need to deposit some amount 
    if(msg.value <= smallCut) throw;

    RemittanceStruct memory newRemittance;
    newRemittance.sender = msg.sender;
    newRemittance.exchangeAddress = _exchangeAddress;
    newRemittance.receiver = _receiver;
    newRemittance.deadline = block.number + _duration;
    newRemittance.isPaidout = false;
    newRemittance.pwHash = _pwHash;
    newRemittance.amount = msg.value - smallCut;
    return true;
  }

  function stringsEqual(string _a, string _b) internal returns (bool) {
    bytes memory a = bytes(_a);
    bytes memory b = bytes(_b);
    return a == b;
  }

  function remit(address sender, address receiver, string pw)
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
