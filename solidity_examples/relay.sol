contract Relay {
  address public currentVersion;
  address public owner;
  
  modifier onlyOwner() {
    if(msg.sender != owner) {
      throw;
    }
    _;
  }

  function Relay(address initAddr) {
    currentVersion = initAddr;
    owner = msg.sender;
  }

  function changeContract(address newVersion)
    public
    onlyOwner()
    {
      currentVersion = newVersion;
    }

  function() {
    if(!currentVersion.delegateCall(msg.data)) throw;
  }
}
