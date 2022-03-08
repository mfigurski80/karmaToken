const LBondManager = artifacts.require('LBondManager');
const CollateralManager = artifacts.require('CollateralManager');

const { getEvents, getRevert } = require('./utils');

contract('CollateralManager', accounts => {
    let libraryInstance;
    let instance;
    const args = { name: 'Test Token', symbol: 'TST', uri: 'http://localhost' };

    before(async () => {
        libraryInstance = await LBondManager.new();
        CollateralManager.link(libraryInstance);
    });

    // beforeEach(async () => {
    //     instance = await CollateralManager.new(args.name, args.symbol, args.uri);
    // });

    // it('allows saving collateral', async () => {
    //     await instance.addERC20Currency(accounts[0]);

    // })
})