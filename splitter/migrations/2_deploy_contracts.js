var Splitter = artifacts.require("./Splitter.sol");

module.exports = function(deployer) {
  var bobAddress = web3.eth.accounts[1];
  var carolAddress = web3.eth.accounts[2];
  deployer.deploy(Splitter, bobAddress, carolAddress);
};
