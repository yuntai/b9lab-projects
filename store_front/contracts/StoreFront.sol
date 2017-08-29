pragma solidity ^0.4.4;

contract StoreFront is Admined {

  struct Product {
    uint price;
    uint stock;
  }

  struct Sale {
    uint productId;
    uint blockNumber
    bytes20 purchaseId;
  }

  struct Purchase {
    uint productId,
    address[] buyers,
    uint deadLine,
    bool isCompleted,
    uint blockNumber,
    mapping(address=>uint) balances;
    mapping(address=>bool) paid;
  }

  mapping(uint => Product) public products;
  Sales[] public sales;
  mapping(bytes20 => Purchase) public purchases;

  event LogAddProduct(address _sender, uint _productId, uint _price, uint _stock);

  function addProduct(uint productId, uint price, uint stock) 
    public
    onlyAdmin
    returns(bool success)
  {
    LogAddProduct(msg.sender, productId, price, stock);

    products[productId].price = price;
    products[productId].stock += stock;

    return true;
  }

  function removeProduct(uint productId)
    public
    onlyAdmin
    returns(bool success)
  {
    LogRemoveProduct(msg.sender, productId);

    require(products[productId].stock > 0);
    products[productId].stock = 0;
  }

  function purchase(uint productId) 
    public
    payable
    ifProductExists
    returns(bool success)
  {
    LogPurchase(msg.sender, id);

    require(products[id].stock > 0);
    require(msg.value > price);
    products[id].stock -= 1;
    Sales memory s = new Sales(id, price, 1);
    salesRecord[msg.sender].push(s);
  }

  // https://ethereum.stackexchange.com/questions/9965/how-to-generate-a-unique-identifier-in-solidity
  // TODO: internal call w/o transaction how?
  function generateCoPurchaseId(uint productId, address buyer0, address buyer1)
    private
    returns(bytes20 coPurchaseId)
  {
    bytes20 coPurchaseId = bytes20(keccak256(productId, buyer0, buyer1, block.number));
    while(coPurchaseId[blobId].blockNumber != 0) {
      coPurchaseId = bytes20(keccak256(coPurchaseId));
    }
  }

  function coPurchaseInitiate(uint productId, address [] others) 
    public
    payable
    ifProductExists
    returns(coPurchaseId)
  {
    LogCoPurchase(msg.sender, id);

    require(products[id].stock > 0);

    uint numPurchasers = 1 + others.length;
    require(numPurchasers <= COPURCHASE_LIMIT);

    require(msg.value > products[id].price/numPurchasers);

    bytes20 coPurchaseId = generateCoPurchaseId(productId, msg.sender, others);

    products[id].stock -= 1;

    mapping addressSeen (address => bool);

    coPurchases[coPurchaseId].purchasers[msg.sender] = true;
    addressSeen[msg.sender] = true;

    for(uint i=0;i < others.length; i++) {
      require(!addressSeen[others[i]);
      coPurchases[coPurchaseId].purchasers[others[i]] = false;
      addressSeen[others[i]] = true;
    }

    coPurchases[coPurchaseId].productId = productId;
    coPurchases[coPurchaseId].deadline = block.number + duration;
    coPurchases[coPurchaseId].numPaid = 1;
    coPurchases[coPurchaseId].blockNumber = block.number;

    buyerBalances[msg.sender] += msg.value;
  }

  function coPurchasePay(coPurchaseId)
    public
    payable
    ifProductExists
    returns(bool success) 
  {
    require(coPurchaseExists[coPurchaseId]);
    require(!coPurchases[coPurchaseId].completed);
    require(coPurchases[coPurchaseId].deadline <= block.number);
    uint productId = coPurchases[coPurchaseId].productId;
    require(msg.value > products[productId].price/2);
    coPurchases[coPurchaseId].completed = true;

    Sales memory s = new Sales(id, price, 1);
    salesRecord[msg.sender].push(s);

    balances[coPurchases[coPurchaseId].buyer0] = 0;
  }

  function coPurchaseRefund(coPurchaseId)
    public
    returns(bool success)
  {
    require(coPurchaseExists[coPurchaseId]);
    require(!coPurchases[coPurchaseId].completed);
    require(coPurchases[coPurchaseId].deadline > block.number);
    require(customerBalances[msg.sender] > 0);

    uint amountToSend = customerBalances[msg.sender];
    balances[msgs.sender] = 0;

    msg.sender.transfer(amountToSend);
    return true;
  }

  function deposit()
    public
    payable
    onlyOwner
    returns(bool)
  {
    return true;
  }

  function withdraw(uint amount)
    public
    onlyOwner
    returns(bool)
  {
    require(amount < this.balance);
    owner.transfer(amount);
    return true;
  }

  function shutdown()
    public
    onlyOwner
  {
    selfdestruct(owner);
  }
}
