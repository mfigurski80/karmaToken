const LBondManager = artifacts.require('LBondManager');
const ERC20Exposed = artifacts.require('ERC20Exposed');
const ERC721Exposed = artifacts.require('ERC721Exposed');
const CollateralManager = artifacts.require('CollateralManager');

const { getEvent, getRevert, buildBondBytes, CURRENCY_TYPE } = require('./utils');

contract('CollateralManager', accounts => {
    let libraryInstance;
    let erc20Instance;
    let erc721Instance;
    let instance;
    const args = { name: 'Test Token', symbol: 'TST', uri: 'http://localhost' };
    const bondBytes = buildBondBytes({
        flag: false,
        currencyRef: 0, 
        nPeriods: 10, curPeriod: 0,
        startTime: Date.now(), periodDuration: 60 * 60,
        couponSize: 10, faceValue: 10,
        beneficiary: accounts[0], minter: accounts[0]
    });

    before(async () => {
        libraryInstance = await LBondManager.new();
        CollateralManager.link(libraryInstance);
        erc20Instance = await ERC20Exposed.new();
        erc721Instance = await ERC721Exposed.new("name", "symbol", "uri");
    });

    beforeEach(async () => {
        instance = await CollateralManager.new(args.name, args.symbol, args.uri);
    });

    it('allows saving erc20 collateral', async () => {
        // setup: mint to erc20, register it as currency, mint bond
        await erc20Instance.mint(accounts[0], 100);
        await erc20Instance.approve(instance.address, 100);
        let currencyEvent = await instance.addERC20Currency(erc20Instance.address).then(tx => getEvent(tx, 'CurrencyAdded'));
        let bondEvent = await instance.mintBond(bondBytes[0], bondBytes[1]).then(tx => getEvent(tx, 'Transfer'));
        // console.log(`Added Currency id: ${currencyEvent.id.toNumber()}`);
        // console.log(`Created Bond id: ${bondEvent.tokenId.toNumber()}`);
        // test subject: associate some erc20 collateral
        let ev = await instance.addERC20Collateral(bondEvent.tokenId, currencyEvent.id, 10).then(tx => getEvent(tx, 'CollateralAdded'));
        assert.equal(ev.id.toNumber(), bondEvent.tokenId.toNumber());
        assert.equal(ev.collateralType, CURRENCY_TYPE.ERC20);
    });

    it('allows saving erc721 collateral', async () => {
        // setup: mint to erc721, register it as currency, mint bond
        const NFT_ID = 1;
        await erc721Instance.mint(accounts[0], NFT_ID);
        await erc721Instance.setApprovalForAll(instance.address, true);
        let currencyEvent = await instance.addERC721Currency(erc721Instance.address).then(tx => getEvent(tx, 'CurrencyAdded'));
        let bondEvent = await instance.mintBond(bondBytes[0], bondBytes[1]).then(tx => getEvent(tx, 'Transfer'));
        // text subject: associate some erc721 collateral
        let ev = await instance.addERC721Collateral(bondEvent.tokenId, currencyEvent.id, NFT_ID).then(tx => getEvent(tx, 'CollateralAdded'));
        assert.equal(ev.id.toNumber(), bondEvent.tokenId.toNumber());
        assert.equal(ev.collateralType, CURRENCY_TYPE.ERC721);
    });
})