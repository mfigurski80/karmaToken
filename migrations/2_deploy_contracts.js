const CollateralManager = artifacts.require('./CollateralManager.sol');
const LoanToken = artifacts.require('./LoanToken.sol');

module.exports = async function(deployer) {
  await deployer.deploy(CollateralManager);
  collateralManager = await CollateralManager.deployed();
  await deployer.deploy(LoanToken, collateralManager.address);
}