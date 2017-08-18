pragma solidity ^0.4.6;

contract SplitterHub {
  
  address public owner;

  struct SplitterStruct {
    address owner;
    address receiver0;
    address receiver1;
    bool isOpen;
  }

  SplitterStruct[] public splitterStructs;

  function SplitterHub() {
    owner = msg.sender;
  }

  function addSplitter(address receiver0, address receiver1)
    public
    returns(bool success) 
  {
    // https://ethereum.stackexchange.com/questions/6756/ways-to-see-if-address-is-empty
    if(receiver0 == address(0) || receiver1 == address(0)) {
      throw;
    }

    SplitterStruct memory newSplitter;
    newSplitter.owner = msg.sender;
    newSplitter.receiver0 = receiver0;
    newSplitter.receiver1 = receiver1;
    newSplitter.isOpen = true;
    splitterStructs.push(newSplitter);
    return true;
  }

  function split()
    public
    payable
    returns(bool success)
  {
    var splitterOwner = msg.sender;
    uint splitterCount = splitterStructs.length;
    for(uint i=0; i<splitterCount; i++) {
      if(splitterStructs[i].owner == splitterOwner) {
        if(!splitterStructs[i].isOpen) throw;

        if(msg.value < 2) throw;

        var amount = msg.value/2;
        
        if(amount * 2 > msg.value) {
          if(!msg.sender.send(1)) {
            return false;
          }
        }
        return splitterStructs[i].receiver0.send(amount) &&
          splitterStructs[i].receiver1.send(amount);
      }
    }
    throw;
  }

  function removeSplitter()
    public
    returns(bool success)
  {
    var splitterOwner = msg.sender;
    uint splitterCount = splitterStructs.length;
    for(uint i=0; i<splitterCount; i++) {
      if(splitterStructs[i].owner == splitterOwner) {
        return splitterStructs[i].isOpen = false;
      }
    }
    throw;
  }

  function kill() public {
    if(msg.sender != owner) throw;
    suicide(owner);
  }

  // add fallback function
  function() payable { }
}

