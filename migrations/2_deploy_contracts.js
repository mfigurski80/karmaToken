const LoanToken = artifacts.require('./LoanToken.sol');

module.exports = function(deployer) {
  deployer.deploy(LoanToken);
}