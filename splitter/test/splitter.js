var Splitter = artifacts.require("./Splitter.sol");

contract('Splitter', function(accounts) {
  var owner = accounts[0];
  var alice = accounts[1];
  var bob = accounts[2];
  var carol = accounts[3];
  var gasPrice = web3.eth.gasPrice;

  beforeEach(function() {
    return Splitter.new({from: owner})
      .then(function(instance) {
        contract = instance;
      });
  });

  it("should split evenly", function() {
    var fund = web3.toBigNumber(200);
    var bobBalance0 = web3.eth.getBalance(bob);

    return contract.split(bob, carol, {from: alice, value: fund, gasPrice: gasPrice})
      .then(function(txn) {
        return contract.withdrawalAmount(bob);
      })
      .then(balance => {
        assert.strictEqual(fund.divToInt(2).eq(balance), true, "fund split evenly");
        return contract.withdrawalAmount(carol);
      })
      .then(balance => {
        assert.strictEqual(fund.divToInt(2).eq(balance), true, "fund split evenly");
        return contract.withdraw({from: bob, gasPrice: gasPrice});
      })
      .then(txn => {
        console.log(txn);
        var gasUsed = web3.toBigNumber(txn.receipt.cumulativeGasUsed).mul(gasPrice);
        var predBobBalance = web3.eth.getBalance(bob).plus(gasUsed).sub(fund.divToInt(2));
        assert.strictEqual(predBobBalance.eq(bobBalance0), true, "fund withdrawn successfully");
        return contract.withdrawalAmount(bob);
      })
      .then(balance => {
        assert.strictEqual(balance.eq(web3.toBigNumber(0)), true, "whole fund withdrawn");
      });
  });

  it("should split evenly and the changes left for the sender", function() {
    var fund = web3.toBigNumber(201);

    return contract.split(bob, carol, {from: alice, value: fund, gasPrice: gasPrice})
      .then(function(txn) {
        return contract.withdrawalAmount(alice);
      })
      .then(balance => {
        assert.strictEqual(balance.eq(web3.toBigNumber(0)), true, "the changes left for the sender");
      });
  });

  it("should throw non-splittable amount(<2)", function() {
    var fund = web3.toBigNumber(1);
    var errorMessage = "VM Exception while processing transaction: invalid opcode"

    return contract.split(bob, carol, {from: alice, value: fund})
      .then(function(txn) {
      })
      .then(assert.fail)
      .catch(function(error) {
        assert(error.message.indexOf(errorMessage) >= 0, 'reject for non-splittable amount');
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
        return contract.split(bob, carol, {from: alice, value: fund, gasPrice: gasPrice})
          .then(function(txn) {
            assert.isOk(txn, "split should go through but");
            var gasUsed = web3.toBigNumber(txn.receipt.cumulativeGasUsed).mul(gasPrice);
            var M = web3.eth.getBalance(alice).plus(fund).plus(gasUsed);
            assert.strictEqual(M.eq(aliceBalance0), true, "Alice's balance decreased");

            //var N = web3.eth.getBalance(alice).plus(gasUsed);
            //assert.strictEqual(web3.eth.getBalance(bob).eq(bobBalance0), true, "Bob's balance doesn't increase");
            //assert.strictEqual(web3.eth.getBalance(carol).eq(carolBalance0), true, "Carol's balance doesn't increase");
            return contract.withdrawalAmount(bob)
          });
      }).then(balance => {
        assert.strictEqual(balance.eq(web3.toBigNumber(0)), true, "balance not increased. the contract not functioning");
        return web3.eth.getBalance(contract.address);
      });
  });

  it("should reject killing not by owner", () => {
    var errorMessage = "VM Exception while processing transaction: invalid opcode"
    return contract.kill({from: alice})
      .then(assert.fail)
      .catch(function(error) {
        assert(error.message.indexOf(errorMessage) >= 0, 'should reject killing not by owner');
      });
  });

  it("testing non-payable fallback function", function() {
    var errorMessage = "VM Exception while processing transaction: invalid opcode"
    var fund = web3.toBigNumber(20000);
    return contract.sendTransaction({value: fund})
    .then(assert.fail)
    .catch(function(error) {
      assert(error.message.indexOf(errorMessage) >= 0, 'should reject value transfer');
    });
  });
});
