const Web3 = require("web3");
const Promise = require("bluebird");
const truffleContract = require("truffle-contract");
const $ = require("jquery");

const metaCoinJson = require("../../build/contracts/MetaCoin.json");
console.log("metaCoinJson=",metaCoinJson);

require("file-loader?name=../index.html!../index.html");

if(typeof web3 !== 'undefined') {
  // Use the Mist/wallet/Metamask provider.
  window.web3 = new Web3(web3.currentProvider);
  console.log("currentProvider used", web3.currentProvider);
} else {
  window.web3 = new Web3(new Web3.providers.HttpProvider('http://localhost:8545'));
}

Promise.promisifyAll(web3.eth, { suffix: "Promise" });
Promise.promisifyAll(web3.version, { suffix: "Promise" });

const MetaCoin = truffleContract(metaCoinJson);
MetaCoin.setProvider(web3.currentProvider);

window.addEventListener('load', function() {
  console.log("load event listener");
  $("#send").click(sendCoin);
  return web3.eth.getAccountsPromise()
    .then(accounts => {
      console.log("accounts=", accounts);
      if(accounts.length == 0) {
        $("#balance").html("N/A");
        throw new Error("No account with which to transfer");
      }
      window.account = accounts[0];
      console.log("Account=", account);
      console.log("MetaCoin=", MetaCoin);
      console.log("MetaCoin.deployed()=", MetaCoin.deployed());
      return MetaCoin.deployed();
    })
    .then(deployed => {
      console.log("deployed=",deployed);
      console.log("window.account",window.account);
      return deployed.getBalance.call(window.account);
    })
    .then(balance => {
      console.log("balance=", balance);
      $("#balance").html(balance.toString(10));
    })
    .catch(console.log);
});

const sendCoin = function() {
  let deployed;
  return MetaCoin.deployed()
    .then(_deployed => {
      deployed = _deployed;
      // .sendTransaction so that we can get the txHash immediately.
      console.log("about to call _deployed.sendCoin()");
      return _deployed.sendCoin.sendTransaction(
          $("input[name='recipient']").val(),
          $("input[name='amount']").val(),
          { from: window.account });
    })
    .then(txHash => {
      $("#status").html("Transaction on the way " + txHash);
      // Now we wait for the tx to be mined.
      const tryAgain = () => web3.eth.getTransactionReceiptPromise(txHash)
        .then(receipt => receipt !== null ?
            receipt :
            Promise.delay(100).then(tryAgain));
      return tryAgain();
    })
    .then(receipt => {
      if(receipt.logs.length == 0) {
        console.error("Empty logs");
        console.error(receipt);
        $("#status").html("There was an error in the tx execution");
      } else {
        // Format the event nicely.
        console.log(deployed.Transfer().formatter(receipt.logs[0]).args);
        $("#status").html("Transfer executed");
      }
      
      return deployed.getBalance.call(window.account);
    })
    .then(balance => $("#balance").html(balance.toString(10)))
    .catch(e => {
      $("#status").html(e.toString());
      console.error(e);
    });
};

