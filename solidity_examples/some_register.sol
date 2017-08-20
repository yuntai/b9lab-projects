contract SomeRegister {
  address backendContract;
  address[] previousBackends;
  address owner;

  function SomeRegister() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    if (msg.sender != owner) {
      throw;
    }
    _;
  }

  function changeBackend(address newBackend) 
    public
    onlyOnwer()
    returns (bool)
  {
    if(newBackend != backendContract) {
      previousBackends.push(backendContract);
      backendContract = newBackend;
      return true;
    }
    return false;
  }
}
