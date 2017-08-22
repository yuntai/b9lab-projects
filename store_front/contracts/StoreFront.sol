pragma solidity ^0.4.4;

contract StoreFront {
  address owner;
  address administrator;

  struct Product {
    uint id;
    uint price;
    uint stock;
  }

  struct Sales {
    uint productId;
    uint blockNumber
  }

  struct CoPurchase {
    uint productId,
    address buyer0,
    address buyer1,
    uint deadLine,
    bool completed,
    uint blockNumber
  }

  mapping products public (uint => Product);
  mapping productExists public (uint => bool);

  mapping salesRecord public (address => Sales[]);
  mapping coPurchases public (bytes20 => CoPurchase);

  uint revenue = 0;

  function StoreFront() {
    owner = msg.sender;
  }

  function addProduct(uint id, uint price, uint stock) 
    public
    onlyAdministrator
    ifProductNotExists
    returns(bool success)
  {
    LogAddProduct(msg.sender, id, price, stock);

    products[id].id = id;
    products[id].price = price;
    products[id].stock = stock;

    return true;
  }

  function purchase(uint id) 
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

  function coPurchaseInitiate(uint productId, address other) 
    public
    payable
    ifProductExists
    returns(coPurchaseId)
  {
    LogCoPurchase(msg.sender, id);

    require(products[id].stock > 0);
    require(msg.value > products[id].price/2);

    bytes20 coPurchaseId = generateCoPurchaseId(productId, msg.sender, other);
    products[id].stock -= 1;

    coPurchases[coPurchaseId].buyer0 = msg.sender;
    coPurchases[coPurchaseId].buyer1 = other;
    coPurchases[coPurchaseId].productId = id;
    coPurchases[coPurchaseId].deadline = block.number + duration;
    coPurchases[coPurchaseId].completed = false;
    coPurchases[coPurchaseId].blockNumber = block.number;

    balances[msg.sender] += msg.value;
  }

  function coPurchaseRefund(coPurchaseId)
    public
    returns(bool success)
  {
    require(coPurchaseExists[coPurchaseId]);
    require(!coPurchases[coPurchaseId].completed);
    require(coPurchases[coPurchaseId].deadline > block.number);
    uint amountToSend = balances[msg.sender];
  }

  function coPurchaseComplete(coPurchaseId)
    public
    payable
    returns(bool success) 
  {
    require(coPurchaseExists[coPurchaseId]);
    require(!coPurchases[coPurchaseId].completed);
    require(coPurchases[coPurchaseId].deadline <= block.number);
    require(msg.value > products[id].price/2);
    coPurchases[coPurchaseId].completed = true;

    Sales memory s = new Sales(id, price, 1);
    salesRecord[msg.sender].push(s);

    balances[coPurchases[coPurchaseId].buyer0] = 0;
  }
}
