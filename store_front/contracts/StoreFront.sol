pragma solidity ^0.4.4;

import "./Admined.sol";

contract StoreFront is Admined {
  struct Product {
    uint price;
    uint stock;
    string sku;
  }

  struct CoPurchase {
    uint productId;
    uint deadlineHour;
    bool isCompleted;
    mapping(address => uint) balances;
    uint numPaid;
    address[] purchasers; //TODO: should be better at the end?
  }

  uint hourLimit;
  uint storeBalance;
  uint coPurchasePendingBalance; // total balance wiating for completion of
                                 // co-purchases

  //TODO: hash product id
  mapping(uint => Product) public products;
  //TODO: purchaseId
  mapping(bytes20 => CoPurchase) public coPurchases;

  event LogAddProduct(address _sender, uint _productId, uint _price, uint _stock);
  event LogRemoveProduct(address _sender, uint _productId, uint _price, uint _stock);

  event LogPurchase(address _sender, uint _productId, uint _numItems, address purchaser);
  event LogCoPurchaseOpen(address _sender, uint _coPurchaseId, uint _productId, uint numItems, address[] _purchasers, uint amount);
  event LogCoPayment(address _sender, bytes20 _coPurchaseId);
  event LogCoPurchaseCompleted(address _sender, bytes20 _coPurchaseId);

  event LogCoPurchaseExpired(address _sender, bytes20 _coPurchaseId);
  event LogCoPurchaseRefund(address _sender, bytes20 _coPurchaseId);

  // TODO: hour type?
  function StoreFront(address owner, uint _coPurchaseLimit, uint _hourLimit) {
    //TODO: super(admin)
    coPurchaseLimit = _coPurchaseLimit;
    hourLimit = _hourLimit;
  }

  // github.com/b9lab/product-payment/contracts/Daylimit.sol
  function currentHour() private constant returns (uint) { return now / 1 hours; }

  // add or update price (if exists)
  function addProduct(uint productId, uint price, uint numItems) 
    public
    onlyAdmin
    returns(bool success)
  {
    LogAddProduct(msg.sender, productId, price, numItems);

    products[productId].price = price;
    products[productId].stock += numItems;

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

  function purchase(uint productId, uint numItems) 
    public
    payable
    ifProductExists
    returns(bool success)
  {
    require(numItems > 0);
    require(products[productId].stock >= numItems);

    var totalPrice = price * numItems;

    require(msg.value > tot);

    products[id].stock -= numItems;
    storeBalance += totalPrice;

    LogPurchase(msg.sender, productId, numItems, price, total, now);
  }

  // https://ethereum.stackexchange.com/questions/9965/how-to-generate-a-unique-identifier-in-solidity
  // TODO: internal call w/o transaction how?
  function generateCoPurchaseId(uint productId, address buyer0, address buyer1)
    private
    returns(bytes20 coPurchaseId)
  {
    coPurchaseId = bytes20(keccak256(productId, buyer0, buyer1, block.number));
    while(coPurchaseId[blobId].blockNumber != 0) {
      coPurchaseId = bytes20(keccak256(coPurchaseId));
    }
  }

  function noDuplicateAddress(address one, address[] others) 
    internal
    returns(bool success)
  {
    mapping(address => bool) memory addressSeen;
    addressSeen[msg.sender] = true;
    for(uint i=0;i < others.length; i++) {
      if(!addressSeen[others[i]]) return false;
      addressSeen[others[i]] = true;
    }
    return true;
  }

  function coPurchaseOpen(uint productId, 
                      uint numItems, 
                      address [] others,
                      uint duration) 
    public
    payable
    ifProductExists
    returns(coPurchaseId)
  {

    require(numItems > 0);
    require(products[productId].stock >= numItems);
    require(noDuplicateAddress(others));

    uint numPurchasers = 1 + others.length;
    require(numPurchasers <= coPurchaseLimit);

    //TODO: split logic
    var totalPrice = products[productId].price * numItems;
    require(msg.value > totalPrice/numPurchasers);

    products[productId].stock -= numItems;

    bytes20 coPurchaseId = generateCoPurchaseId(productId, msg.sender, others);

    var coPurchase = coPurchases[coPurchaseId];
    coPurchase.purchasers             = others;
    coPurchase.purchasers.push(msg.sender);
    coPurchase.numPaid                = 1;
    coPurchase.productId              = productId;
    coPurchase.deadlineHour           = currentHour() + 1 + hourLimit;
    coPurchase.blockNumber            = block.number;
    coPurchase.balances[msg.sender]  += msg.value;
    coPurchase.completed              = false;
    coPurchase.totalPrice             = totalPrice;

    coPurchasePendingBalance += msg.value;

    LogCoPurchase(msg.sender, numItems, others);
  }

  function coPurchasePay(coPurchaseId)
    public
    payable
    returns(bool success) 
  {
    require(coPurchaseExists[coPurchaseId]);
    require(coPurchases[coPurchaseId].numPaid < coPurchases[coPurchaseId].purchasers.length);
    require(coPurchases[coPurchaseId].deadlineHour <= currentHour());

    var coPurchase = coPurchases[coPurchaseId];

    //TODO: 1/N problem
    require(msg.value >
            products[coPurchase.productId].price/coPurchases.numPurchasers);
    coPurchase.numPaid += 1;

    if(coPurchases.numPaid == coPurchases.purchasers.length) {
      coPurchases.completed = true;
      delete coPurchases[coPurchaseId]; //TODO: does it delete entry?
      for(uint i=0;i<coPurchases.purchasers.length;i++) {
        coPurchases.balances[coPurchase.purchasers[i]] = 0;
      }
      coPurchasePendingBalance -= coPurchases.totalPrice;
      storeBalance += coPurchases.totalPrice;
      LogCoPurchaseDone();
    }
    else {
      coPurchases[coPurchaseId].balances[msg.sender] += msg.value;
      coPurchasePendingBalance += msg.value;
    }
  }

  //TODO: caveat with hour
  function coPurchaseRefund(coPurchaseId)
    public
    returns(bool success)
  {
    require(coPurchaseExists[coPurchaseId]);
    require(!coPurchases[coPurchaseId].completed);
    //TODO: use date/time instead of block number
    require(coPurchases[coPurchaseId].deadlineHour > currentHour());
    require(coPurchases[coPurchaseId].balances[msg.sender] > 0);

    uint amountToSend = coPurchases[coPurchaseId].balances[msg.sender];
    coPurchases[coPurchaseId].balances[msg.sender] = 0;

    msg.sender.transfer(amountToSend);

    return true;
  }

  function deposit()
    public
    payable
    onlyOwner
  { 
    storeBalance += msg.amount;
  }

  function withdraw(uint amount)
    public
    onlyOwner
    returns(bool)
  {
    // only available coPurchasePending balance
    // understnd reentry attach again
    // this.balance changes before owner.transfer?
    require(amount < storeBalance - coPurchasePendingBalance);
    storeBalance -= amount;
    owner.transfer(amount);
    return true;
  }

  function shutdown()
    public
    onlyOwner
  {
    require(coPurchasePendingBalance == 0);
    selfdestruct(owner);
  }
}
