var Campaign = artifacts.require("./Campaign.sol");

module.exports = function(deployer) {
  console.log(web3.eth.accounts);
  deployer.deploy(Campaign, 100, web3.toBigNumber(10000000));
};
