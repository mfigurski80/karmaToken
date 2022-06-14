const LBondManager = artifacts.require('LBondManager');
const ERC20Exposed = artifacts.require('ERC20Exposed');
const ERC721Exposed = artifacts.require('ERC721Exposed');
const ERC1155Exposed = artifacts.require('ERC1155Exposed');
const CollateralManager = artifacts.require('CollateralManager');

const { getEvent, getRevert, buildBondBytes, increaseTime, CURRENCY_TYPE } = require('./utils');

contract('CollateralManager', accounts => {
    let libraryInstance;
    let erc20Instance;
    let erc721Instance;
    let erc1155Instance;
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
        erc721Instance = await ERC721Exposed.new(args.name, args.symbol, args.uri);
        erc1155Instance = await ERC1155Exposed.new();
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
        // test subject: associate some erc721 collateral
        let ev = await instance.addERC721Collateral(bondEvent.tokenId, currencyEvent.id, NFT_ID).then(tx => getEvent(tx, 'CollateralAdded'));
        assert.equal(ev.id.toNumber(), bondEvent.tokenId.toNumber());
        assert.equal(ev.collateralType, CURRENCY_TYPE.ERC721);
    });

    it('allows saving erc1155 token collateral', async () => {
        // setup: mint to erc1155, register it as currency, mint bond
        const TOKEN_ID = 1;
        await erc1155Instance.mint(accounts[0], TOKEN_ID, 100);
        await erc1155Instance.setApprovalForAll(instance.address, true);
        let currencyEvent = await instance.addERC1155TokenCurrency(erc1155Instance.address, TOKEN_ID).then(tx => getEvent(tx, 'CurrencyAdded'));
        let bondEvent = await instance.mintBond(bondBytes[0], bondBytes[1]).then(tx => getEvent(tx, 'Transfer'));
        // test subject: associate some erc1155 collateral
        let ev = await instance.addERC1155TokenCollateral(bondEvent.tokenId, currencyEvent.id, 10).then(tx => getEvent(tx, 'CollateralAdded'));
        assert.equal(ev.id.toNumber(), bondEvent.tokenId.toNumber());
        assert.equal(ev.collateralType, CURRENCY_TYPE.ERC1155Token);
    });

    it('allows saving erc1155 nft collateral', async () => {
        // setup: mint to erc1155, register it as currency, mint bond
        const NFT_ID = 2;
        await erc1155Instance.mint(accounts[0], NFT_ID, 1);
        await erc1155Instance.setApprovalForAll(instance.address, true);
        let currencyEvent = await instance.addERC1155NFTCurrency(erc1155Instance.address).then(tx => getEvent(tx, 'CurrencyAdded'));
        let bondEvent = await instance.mintBond(bondBytes[0], bondBytes[1]).then(tx => getEvent(tx, 'Transfer'));
        // test subject: associate some erc1155 collateral
        let ev = await instance.addERC1155NFTCollateral(bondEvent.tokenId, currencyEvent.id, NFT_ID).then(tx => getEvent(tx, 'CollateralAdded'));
        assert.equal(ev.id.toNumber(), bondEvent.tokenId.toNumber());
        assert.equal(ev.collateralType, CURRENCY_TYPE.ERC1155NFT);
    });

    it('allows releasing collateral to bond minter', async () => {
        const TOKEN_ID = 3;
        const OPERATOR = accounts[0];
        await erc1155Instance.mint(OPERATOR, TOKEN_ID, 100);
        await erc1155Instance.setApprovalForAll(instance.address, true);
        let currencyEvent = await instance.addERC1155TokenCurrency(erc1155Instance.address, TOKEN_ID).then(tx => getEvent(tx, 'CurrencyAdded'));
        let bondEvent = await instance.mintBond(bondBytes[0], bondBytes[1]).then(tx => getEvent(tx, 'Transfer'));
        let collateralEvent = await instance.addERC1155TokenCollateral(bondEvent.tokenId, currencyEvent.id, 100).then(tx => getEvent(tx, 'CollateralAdded'));
        // test subject: release collateral fails when bond ISN'T complete
        let err = await getRevert(instance.releaseCollaterals([bondEvent.tokenId], [collateralEvent.id], OPERATOR));
        assert.include(err.reason.toLowerCase(), 'collateral');
        assert.include(err.reason.toLowerCase(), 'authorized');
        // test subject: release collateral succeeds when bond IS complete
        await instance.forgiveBond(bondEvent.tokenId);
        // let ev = await instance._isAuthorizedToReleaseCollateral(bondEvent.tokenId, accounts[0]);
        let ev = await instance.releaseCollaterals([bondEvent.tokenId], [collateralEvent.id], OPERATOR).then(tx => getEvent(tx, 'CollateralReleased'));
        assert.equal(ev.bondId.toNumber(), bondEvent.tokenId.toNumber());
        assert.equal(ev.collateralId.toNumber(), collateralEvent.id);
        assert.equal(ev.to, OPERATOR);
        // test subject: release collateral has proper side effects
        let numOwned = await erc1155Instance.balanceOf(OPERATOR, TOKEN_ID);
        assert.equal(numOwned.toNumber(), 100);
    });

    it('allows releasing collateral to bond owner', async () => {
        const TOKEN_ID = 4;
        const OPERATOR = accounts[0];
        await erc1155Instance.mint(OPERATOR, TOKEN_ID, 100);
        await erc1155Instance.setApprovalForAll(instance.address, true);
        let currencyEvent = await instance.addERC1155TokenCurrency(erc1155Instance.address, TOKEN_ID).then(tx => getEvent(tx, 'CurrencyAdded'));
        let bondEvent = await instance.mintBond(bondBytes[0], bondBytes[1]).then(tx => getEvent(tx, 'Transfer'));
        let collateralEvent = await instance.addERC1155TokenCollateral(bondEvent.tokenId, currencyEvent.id, 100).then(tx => getEvent(tx, 'CollateralAdded'));
        // test subject: release collateral fails when bond ISN'T defaulted
        let err = await getRevert(instance.releaseCollaterals([bondEvent.tokenId], [collateralEvent.id], OPERATOR));
        assert.include(err.reason.toLowerCase(), 'collateral');
        assert.include(err.reason.toLowerCase(), 'authorized');
        // test subject: release collateral succeeds when bond IS defaulted
        await increaseTime(1000*60*60*24*256);
        let defaultEvent = await instance.callBond(bondEvent.tokenId).then(tx => getEvent(tx, 'BondDefaulted'));
        assert.equal(defaultEvent.id.toNumber(), bondEvent.tokenId.toNumber());
        let ev = await instance.releaseCollaterals([bondEvent.tokenId], [collateralEvent.id], OPERATOR).then(tx => getEvent(tx, 'CollateralReleased'));
        assert.equal(ev.bondId.toNumber(), bondEvent.tokenId.toNumber());
        assert.equal(ev.collateralId.toNumber(), collateralEvent.id);
        assert.equal(ev.to, OPERATOR);
        // test subject: release collateral has proper side effects
        let numOwned = await erc1155Instance.balanceOf(OPERATOR, TOKEN_ID);
        assert.equal(numOwned.toNumber(), 100);
    });
});