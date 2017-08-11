pragma solidity ^0.4.4;

contract Remittance {
  address public owner;
	address public sender;
  address public exchangeAddress;
  string 	public pwhash;
  uint 		public sendAmount;

  uint    public deadline;
	uint		public deadlineLimit;

  function Remittance(_exchangeAddress, _pwhash, _sendAmount) payable {
    owner = msg.sender;
		exchangeAddress = _exchangeAddress;
    pwhash = _pwhash;
    sendAmount = _sendAmount;
  }

  function remit(string _pw1, string _pw2) 
    public
    returns (bool success) 
  {
    if(msg.sender != exchangeAddress) throw;
    _pwhash = keccak256(_pw1 + _pw2);
    if(pwhash != _pwhash) throw;
    return exchangeAddress.send(sendAmount);
  }

	function killMe() returns (bool) {
  	if (msg.sender == owner) {
    	suicide(owner);
      return true;
    }
	}

	function () payable {}
}
