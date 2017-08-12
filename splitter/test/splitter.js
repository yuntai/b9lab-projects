var Splitter = artifacts.require("./Splitter.sol");

contract('Splitter', function(accounts) {
  var owner = accounts[0];
  var alice = accounts[1];
  var bob = accounts[2];
  var carol = accounts[3];
  var gasPrice = web3.eth.gasPrice;

  beforeEach(function() {
    return Splitter.new(bob, carol, {from: owner})
      .then(function(instance) {
        contract = instance;
      });
  });

  it("should split evenly", function() {
    var fund = web3.toBigNumber(200);

    var bobBalance0 = web3.eth.getBalance(bob);
    var carolBalance0 = web3.eth.getBalance(bob);
    var aliceBalance0 = web3.eth.getBalance(alice);

    return contract.split({from: alice, value: fund, gasPrice: gasPrice})
      .then(function(txn) {
        var b = web3.eth.getBalance(bob).sub(bobBalance0);
        var c = web3.eth.getBalance(carol).sub(carolBalance0);

        assert.strictEqual(b.eq(c), true, "fund not split evenly")
        assert.strictEqual(fund.divToInt(2).eq(b), true, "fund not split evenly");
        assert.strictEqual(c.mul(2).eq(fund), true, "fund not split evenly")
      });
  });

  it("should split evenly and the changes sent back to the sender", function() {
    var fund = web3.toBigNumber(201);

    var bobBalance0 = web3.eth.getBalance(bob);
    var carolBalance0 = web3.eth.getBalance(bob);
    var aliceBalance0 = web3.eth.getBalance(alice);

    return contract.split({from: alice, value: fund, gasPrice: gasPrice})
      .then(function(txn) {
        var gasUsed = web3.toBigNumber(txn.receipt.cumulativeGasUsed).mul(gasPrice);
        var M = web3.eth.getBalance(alice).plus(fund).plus(gasUsed).sub(1);

        var b = web3.eth.getBalance(bob).sub(bobBalance0);
        var c = web3.eth.getBalance(carol).sub(carolBalance0);

        assert.strictEqual(b.eq(c), true, "fund not split evenly")
        assert.strictEqual(fund.divToInt(2).eq(b), true, "fund not split evenly");
        assert.strictEqual(c.mul(2).eq(fund.sub(1)), true, "the changes not sent back to the sender")
      });
  });

  it("should throw non-splittable amount", function() {
    var fund = web3.toBigNumber(1);
    var errorMessage = "VM Exception while processing transaction: invalid JUMP at"

    return contract.split({from: alice, value: fund})
      .then(function(txn) {
      })
      .then(assert.fail)
      .catch(function(error) {
        assert(error.message.indexOf(errorMessage) >= 0, 'should throw non-splittable amount.');
      });
  });

  it("should sucide by kill signal by owner", function() {
    var fund = web3.toBigNumber(100000000);
    var bobBalance0 = web3.eth.getBalance(bob);
    var carolBalance0 = web3.eth.getBalance(bob);
    var aliceBalance0 = web3.eth.getBalance(alice);

    return contract.kill({from: owner})
      .then(function(txn) {
        assert.isOk(txn, "kill should go through from owner");
        return contract.split({from: alice, value: fund, gasPrice: gasPrice})
          .then(function(txn) {
            assert.isOk(txn, "split should go through but");
            var gasUsed = web3.toBigNumber(txn.receipt.cumulativeGasUsed).mul(gasPrice);
            var M = web3.eth.getBalance(alice).plus(fund).plus(gasUsed);
            var N = web3.eth.getBalance(alice).plus(gasUsed);

            assert.strictEqual(web3.eth.getBalance(bob).eq(bobBalance0), true, "Bob's balance doesn't increase");
            assert.strictEqual(web3.eth.getBalance(carol).eq(carolBalance0), true, "Carol's balance doesn't increase");
            assert.strictEqual(M.eq(aliceBalance0), true, "Alice's balance decreased");
          })
      });
  });

  it("should reject killing not by owner", function() {
    var errorMessage = "VM Exception while processing transaction: invalid JUMP at"
    return contract.kill({from: alice})
      .then(assert.fail)
      .catch(function(error) {
        assert(error.message.indexOf(errorMessage) >= 0, 'should reject killing not by owner');
      });
  });
});
