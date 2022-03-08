const LBondManager = artifacts.require('./LBondManager.sol');
const CollateralManager = artifacts.require('./CollateralManager.sol');

module.exports = async function(deployer) {
  await deployer.deploy(LBondManager);
  bondLibrary = await LBondManager.deployed();
  CollateralManager.link(bondLibrary.address)
  await deployer.deploy(CollateralManager, "A", "B", "C");
}
