const LBondManager = artifacts.require('./LBondManager.sol');
const Core = artifacts.require('./Core.sol');

module.exports = async function(deployer, network, accounts) {
  // console.log(`Deploying LBondManager library... ${network}`);
  await deployer.deploy(LBondManager);
  bondLibrary = await LBondManager.deployed();
  // console.log(`Deploying CollateralManager contract...${network}`);
  deployer.link(LBondManager, Core);
  await deployer.deploy(Core, 
    "BOND On-Network Datastructure", "BOND", "http://google.com");
}
