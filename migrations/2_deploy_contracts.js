const CollateralManager = artifacts.require('./CollateralManager.sol');
const MonetizedLoanNFT = artifacts.require('./MonetizedLoanNFT.sol');

module.exports = async function(deployer) {
  await deployer.deploy(CollateralManager);
  collateralManager = await CollateralManager.deployed();
  await deployer.deploy(MonetizedLoanNFT, collateralManager.address);
}
