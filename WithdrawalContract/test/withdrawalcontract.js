var WithdrawalContract = artifacts.require("./WithdrawalContract.sol");

contract('WithdrawalContract', function(accounts) {
  var owner = accounts[0];
  var alice = accounts[1];
  var fund = web3.toBigNumber(100000000);
  var gasPrice = web3.eth.gasPrice;

  beforeEach(function() {
    return WithdrawalContract.new({from: owner, value: 1000})
      .then(function(instance) {
        contract = instance;
      });
  });

  it("should put 10000 MetaCoin in the first account", function() {
    var aliceBalance = web3.eth.getBalance(alice);
    var contractBalance = web3.eth.getBalance(contract.address);
    console.log("aliceBalance=", aliceBalance);
    console.log("contractBalance=",contractBalance);

    return contract.becomeRichest({from: alice, value: fund, gasPrice: gasPrice})
      .then(function(txn) {
        var gasUsed = web3.toBigNumber(txn.receipt.cumulativeGasUsed).mul(gasPrice);
        var M = web3.eth.getBalance(alice).plus(fund).plus(gasUsed);
        console.log("M=",M);
        var contractBalance = web3.eth.getBalance(contract.address);
        console.log("contractBalance(after)=",contractBalance);
      })
  });
});
