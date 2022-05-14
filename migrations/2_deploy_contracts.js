const LBondManager = artifacts.require('./LBondManager.sol');
const CollateralManager = artifacts.require('./CollateralManager.sol');

module.exports = async function(deployer, network, accounts) {
  console.log(`Deploying LBondManager library... ${network}`);
  await deployer.deploy(LBondManager);
  bondLibrary = await LBondManager.deployed();
  console.log(`Deploying CollateralManager contract...${network}`);
  deployer.link(LBondManager, CollateralManager);
  await deployer.deploy(CollateralManager, "About", "Bichin", "Time").catch(() => {});
}
