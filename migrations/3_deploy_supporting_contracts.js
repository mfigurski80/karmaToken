const ERC20Exposed = artifacts.require('./exposed/ERC20Exposed.sol');
const ERC721Exposed = artifacts.require('./exposed/ERC721Exposed.sol');
const ERC1155Exposed = artifacts.require('./exposed/ERC1155Exposed.sol');

module.exports = async function(deployer, network, accounts) {
    const shouldDeploySupport = process.env.DEPLOY_SUPPORTING_CONTRACTS === 'Y';

    if (shouldDeploySupport) {
        console.log('DEPLOYING SUPPORTING CONTRACTS'); 
        await deployer.deploy(ERC20Exposed);
        await deployer.deploy(ERC721Exposed, "Pics", "PIX", "http://google.com");
        await deployer.deploy(ERC1155Exposed);
    }
}
