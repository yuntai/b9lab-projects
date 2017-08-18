var SplitterHub = artifacts.require("./SplitterHub.sol");

contract('SplitterHub', function(accounts) {
  var owner = accounts[0];

  var alice = accounts[1];
  var bob = accounts[2];
  var carol = accounts[3];
  var david = accounts[4];

  beforeEach(function() {
    return SplitterHub.new({from: owner})
      .then(function(instance) {
        contract = instance;
      });
  });

  it("should create splitter", function() {
    return contract.addSplitter(bob, carol, {from: alice}).then(function(txn) {
    var fund = web3.toBigNumber(1000000);
    var bobBalance0 = web3.eth.getBalance(bob);
    var carolBalance0 = web3.eth.getBalance(bob);
      return contract.split({from: alice, value: web3.toBigNumber(fund)})
        .then(function(txn) {
          var b = web3.eth.getBalance(bob).sub(bobBalance0);
          var c = web3.eth.getBalance(carol).sub(carolBalance0);

          assert.strictEqual(b.eq(c), true, "fund not split evenly")
          assert.strictEqual(fund.divToInt(2).eq(b), true, "fund not split evenly");
          assert.strictEqual(c.mul(2).eq(fund), true, "fund not split evenly")
        });
    });
  });
});
