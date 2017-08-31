pragma solidity ^0.4.4;

contract admined {
  address owner;
  address admin;

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  modifier onlyAdmin {
    require(msg.sender == admin);
    _;
  }

  function admined(address _admin) {
    require(_admin != address(0));
    owner = msg.sender;
  }

  function changeAdmin(address newAdmin) 
    public
    onlyOwner
  {
    admin = newAdmin;
  }
}

contract StoreFront is admined {
  struct Product {
    bool exists;
    uint price;
    uint stock;
  }

  struct CoPurchaserStruct {
    bool exists;
    uint balance;
  }

  struct CoPurchase {
    bool exists;
    bool completed;
    bytes32 productId;
    uint numItems;
    uint deadlineHour;
    uint numPaid;
    uint totalPrice;
    uint pricePerParticipant;
    uint discount;
    uint totalBalance;
    address[] participantsList;
    mapping(address => CoPurchaserStruct) participants;
    bool restocked;
  }


  uint public coPurchaseParticipantNumberLimit; // limit number of participants for co-purchase'ing
  uint public coPurchaseHourLimit;      // number of hours co-purchases open to be paid out
  uint public coPurchaseFee;            // nominal fee to open co-purchase to counter DoS

  uint public storeBalance;             // internal accounting for store balance
  uint public coPurchasePendingBalance; // total balance pending in open co-purcahses

  mapping(address => uint) public customerCredit;     // in case customer paid too much
  mapping(bytes32 => Product) public products;        // product DB
  mapping(bytes32 => CoPurchase) public coPurchases;  // co-purchase DB

  modifier ifProductExists(bytes32 productId) { require(products[productId].exists); _; }
  modifier ifProductNotExists(bytes32 productId) { require(!products[productId].exists); _; }

  modifier ifCoPurchaseExists(bytes32 coPurchaseId) { require(coPurchases[coPurchaseId].exists); _; }

  modifier ifCoPurchaseExpired(bytes32 coPurchaseId) 
  { 
    require(coPurchases[coPurchaseId].deadlineHour > currentHour()); 
    _;
  } 

  modifier ifCoPurchaseNotExpired(bytes32 coPurchaseId) 
  { 
    require(coPurchases[coPurchaseId].deadlineHour <= currentHour()); 
    _;
  } 

  modifier ifCoPurchaseCompleted(bytes32 coPurchaseId) 
  {
    require(coPurchases[coPurchaseId].completed);
    _;
  } 

  modifier ifCoPurchaseNotCompleted(bytes32 coPurchaseId) 
  {
    require(!coPurchases[coPurchaseId].completed);
    _;
  } 

  modifier ifCoPurchaseValidParticipant(bytes32 coPurchaseId)
  {
    require(coPurchases[coPurchaseId].participants[msg.sender].exists);
    _;
  }

  modifier ifCoPurchaseNotYetPaid(bytes32 coPurchaseId)
  {
    require(coPurchases[coPurchaseId].participants[msg.sender].balance == 0);
    _;
  }

  event LogAddProduct(address _sender, bytes32 _productId, uint _price, uint _stock);
  event LogRemoveProduct(address _sender, bytes32 _productId, uint _price, uint _stock);

  event LogPurchase(address _sender, bytes32 _productId, uint _numItems, address purchaser);
  event LogCoPurchaseOpen(address _sender, bytes32 _coPurchaseId, bytes32 _productId, uint numItems, address[] _purchasers, uint amount);
  event LogCoPayment(address _sender, bytes32 _coPurchaseId);
  event LogCoPurchaseComplete(address _sender, bytes32 _coPurchaseId);

  event LogCoPurchaseExpired(address _sender, bytes32 _coPurchaseId);
  event LogCoPurchaseRefund(address _sender, bytes32 _coPurchaseId);

  function StoreFront(address _admin,
                      uint _coPurchaseParticipantNumberLimit, 
                      uint _coPurchaseHourLimit, 
                      uint _coPurchaseFee) 
    admined(_admin)
  {
    require(_coPurchaseParticipantNumberLimit > 0);
    require(_coPurchaseFee > 0);
    require(_coPurchaseHourLimit > 0);

    coPurchaseParticipantNumberLimit = _coPurchaseParticipantNumberLimit;
    coPurchaseHourLimit = _coPurchaseHourLimit;
    coPurchaseFee = _coPurchaseFee;
  }

  // github.com/b9lab/product-payment/contracts/Daylimit.sol
  function currentHour() private constant returns (uint) { return now / 1 hours; }

  // add or update price (if exists)
  function addProduct(bytes32 productId, uint price, uint numItems) 
    public
    onlyAdmin
    ifProductNotExists(productId)
    returns(bool success)
  {
    require(price > 0);
    require(numItems > 0);

    products[productId].exists = true;
    products[productId].price = price;
    products[productId].stock += numItems;

    LogAddProduct(msg.sender, productId, price, numItems);

    return true;
  }

  //TODO: addStock & updatePrice
  function removeProduct(bytes32 productId)
    public
    onlyAdmin
    ifProductExists(productId)
    returns(bool success)
  {
    products[productId].exists = false;
    //LogRemoveProduct(msg.sender, productId);
    return true;
  }

  function purchase(bytes32 productId, uint numItems) 
    public
    payable
    ifProductExists(productId)
    returns(bool success)
  {
    require(numItems > 0);
    require(products[productId].stock >= numItems);

    var totalPrice = products[productId].price * numItems;

    require(msg.value > totalPrice);

    var numStocks = products[productId].stock;
    products[productId].stock -= numItems;

    require(products[productId].stock < numStocks);

    storeBalance += totalPrice;

    //LogPurchase(msg.sender, productId, numItems, price, total, now);
    return true;
  }

  // ethereum.stackexchange.com/questions/9965/how-to-generate-a-unique-identifier-in-solidity
  function generateCoPurchaseId(bytes32 productId, address[] participants)
    internal
    returns(bytes32 coPurchaseId)
  {
    coPurchaseId = keccak256(productId, participants, block.number);
    while(coPurchases[coPurchaseId].exists) {
      coPurchaseId = keccak256(coPurchaseId);
    }
    //TODO: race condition?
  }

  function coPurchaseOpen(bytes32 productId, 
                      uint numItems, 
                      address [] participants,
                      uint durationInHour) 
    public
    payable
    ifProductExists(productId)
    returns(bytes32 coPurchaseId)
  {
    require(numItems > 0);
    require(products[productId].stock >= numItems);
    require(durationInHour <= coPurchaseHourLimit);
    require(participants.length + 1 <= coPurchaseParticipantNumberLimit);

    // got stack too deep exception
    //uint numParticipants = participants.length + 1;

    // small discount with assumption that coPurchaseLimit is a resonably small number
    uint totalPrice = ((products[productId].price * numItems)/(participants.length+1)) * (participants.length+1);
    uint pricePerParticipant = totalPrice/(participants.length+1);

    require(msg.value >= pricePerParticipant + coPurchaseFee);

    uint numStock = products[productId].stock;
    products[productId].stock -= numItems;

    require(products[productId].stock < numStock);

    coPurchaseId = generateCoPurchaseId(productId, participants);

    var coPurchase = coPurchases[coPurchaseId];

    coPurchase.exists                           = true;
    coPurchase.completed                        = false;
    coPurchase.productId                        = productId;
    coPurchase.deadlineHour                     = currentHour() + 1 + durationInHour;
    coPurchase.numPaid                          = 1;
    coPurchase.totalPrice                       = totalPrice;
    coPurchase.pricePerParticipant              = pricePerParticipant;
    coPurchase.discount                         = products[productId].price * numItems - totalPrice;
    coPurchase.totalBalance                    += msg.value - coPurchaseFee;
    coPurchase.participantsList                 = participants;
    coPurchase.participantsList.push(msg.sender);

    // check duplicate address
    for(uint i=0; i < coPurchase.participantsList.length; i++) {
      if(coPurchase.participants[coPurchase.participantsList[i]].exists)
        revert();
      coPurchase.participants[coPurchase.participantsList[i]].exists = true;
    }

    coPurchase.participants[msg.sender].balance += msg.value - coPurchaseFee;


    coPurchasePendingBalance += msg.value - coPurchaseFee;
    storeBalance += coPurchaseFee;

    //LogCoPurchase(msg.sender, numItems, others);
  }


  function coPurchasePay(bytes32 coPurchaseId)
    public
    payable
    ifCoPurchaseExists(coPurchaseId)
    ifCoPurchaseNotExpired(coPurchaseId)
    ifCoPurchaseNotCompleted(coPurchaseId)
    ifCoPurchaseValidParticipant(coPurchaseId)
    ifCoPurchaseNotYetPaid(coPurchaseId)
    returns(bool success) 
  {
    var coPurchase = coPurchases[coPurchaseId];

    require(msg.value >= coPurchase.pricePerParticipant);

    coPurchase.numPaid += 1;
    coPurchases[coPurchaseId].participants[msg.sender].balance += msg.value;
    coPurchases[coPurchaseId].totalBalance += msg.value;

    coPurchasePendingBalance += msg.value;

    //TODO: caveat with hour
    if(coPurchase.numPaid == coPurchase.participantsList.length) {
      coPurchase.completed = true;
      for(uint i = 0; i<coPurchase.participantsList.length; i++) {
        var change =
          coPurchase.participants[coPurchase.participantsList[i]].balance - coPurchase.pricePerParticipant;
        if(change > 0) {
          customerCredit[coPurchase.participantsList[i]] += change;
        }
        coPurchase.participants[coPurchase.participantsList[i]].balance = 0;
      }

      coPurchasePendingBalance -= coPurchase.totalBalance;
      storeBalance += coPurchase.totalPrice;
      //TODO: assert
      //LogCoPurchaseCompleted(msg.sender, coPurchaseId);
      return true;
    }
  }

  // restock co-purchase items that exprired
  function coPurchaseRestock(bytes32 coPurchaseId)
    public
    onlyAdmin
    ifCoPurchaseExists(coPurchaseId)
    ifCoPurchaseNotCompleted(coPurchaseId)
    ifCoPurchaseExpired(coPurchaseId)
    returns(bool success)
  {
    require(!coPurchases[coPurchaseId].restocked);
    coPurchases[coPurchaseId].restocked = true;
    products[coPurchases[coPurchaseId].productId].stock += coPurchases[coPurchaseId].numItems;
    return true;
  }

  // refund when a co-purchase falls apart
  function coPurchaseRefund(bytes32 coPurchaseId)
    public
    ifCoPurchaseExists(coPurchaseId)
    ifCoPurchaseNotCompleted(coPurchaseId)
    ifCoPurchaseExpired(coPurchaseId)
    ifCoPurchaseValidParticipant(coPurchaseId)
    returns(bool success)
  {
    require(coPurchases[coPurchaseId].participants[msg.sender].balance > 0);

    uint amount = coPurchases[coPurchaseId].participants[msg.sender].balance;
    coPurchases[coPurchaseId].participants[msg.sender].balance = 0;

    msg.sender.transfer(amount);

    //LogCoPurchaseRefund(msg.sender, coPurchaseId, amount);
    return true;
  }

  function refundCustomerCredit()
    public
    returns(bool) 
  {
    require(customerCredit[msg.sender] > 0);
    var amount = customerCredit[msg.sender];
    customerCredit[msg.sender] = 0;
    msg.sender.transfer(amount);
    return true;
  }

  function ownerDeposit()
    public
    payable
    onlyOwner
    returns(bool)
  { 
    storeBalance += msg.value;
    //LogOwnerDeposit(msg.sender, msg.value);
    return true;
  }

  function ownerWithdraw(uint amount)
    public
    onlyOwner
    returns(bool)
  {
    require(amount < storeBalance - coPurchasePendingBalance);
    storeBalance -= amount;
    owner.transfer(amount);
    //LogOwnerWithdraw(msg.sender, amount);
    return true;
  }

  function shutdown()
    public
    onlyOwner
  {
    require(coPurchasePendingBalance == 0);
    selfdestruct(owner);
  }

  function () {}
}

//TODO: race btw restock & remove product
