if (typeof web3 !== 'undefined') {
  // Don't lose an existing provider, like Mist or Metamask
  web3 = new Web3(web3.currentProvider);
} else {
  // set the provider you want from Web3.providers
  web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));
}
web3.eth.getCoinbase(function(err, coinbase) {
    if (err) {
        console.log(err);
    } else {
        console.log("Coinbase: " + coinbase);
    }
});

// Your deployed address changes every time you deploy.
var splitterAddress = "0xd9ae1a54e6f517592d7d4a7bd7f5ff2d23861aeb";

var ownerAddress = web3.eth.accounts[0];
var bobAddress = web3.eth.accounts[1];
var carolAddress = web3.eth.accounts[2];
var aliceAddress = web3.eth.accounts[3];

splitterInstance = web3.eth.contract(splitterCompiled.abi).at(splitterAddress);
console.log("splitterInstance=", splitterInstance);

// Query eth for balance
web3.eth.getBalance(splitterAddress, function(err, balance) {
    if (err) {
        console.log(err);
    } else {
        console.log("Contract balance: " + balance);
    }
});

function updateBalance() {
  var bal = web3.eth.getBalance(ownerAddress);
	document.getElementById('owner').innerText = bal;
  bal = web3.eth.getBalance(bobAddress);
	document.getElementById('bob').innerText = bal;
	bal = web3.eth.getBalance(carolAddress);
	document.getElementById('carol').innerText = bal;
	bal = web3.eth.getBalance(aliceAddress);
	document.getElementById('alice').innerText = bal;
  bal = web3.eth.getBalance(splitterAddress);
	document.getElementById('contract').innerText = bal;
}

function split() {
	splitterInstance.split({from: aliceAddress, value: web3.toBigNumber(10000)},function() {
    updateBalance();
	});
}

function kill() {
	splitterInstance.kill({from: web3.eth.accounts[0]});
}
