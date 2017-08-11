var Splitter = artifacts.require("./Splitter.sol");

contract('Splitter', function(accounts) {
  var owner = accounts[0];
  var alice = accounts[1];
  var bob = accounts[2];
  var carol = accounts[3];

  beforeEach(function() {
    return Splitter.new(bob, carol, {from: owner})
      .then(function(instance) {
        contract = instance;
      });
  });

  it("should just say hello", function() {
    assert.strictEqual(true, true, "Somethig is wrong.");
  });

  it("should split evenly", function() {
    var fund = web3.toBigNumber(200);

    var bobBalance0 = web3.eth.getBalance(bob);
    var carolBalance0 = web3.eth.getBalance(bob);

    return contract.split({from: alice, value: fund})
      .then(function(txn) {
        var b = web3.eth.getBalance(bob).sub(bobBalance0);
        var c = web3.eth.getBalance(carol).sub(carolBalance0);

        assert.strictEqual(b.eq(c), true, "fund not split evenly")
        assert.strictEqual(c.mul(2).eq(fund), true, "fund not split evenly")
      });
  });
});
