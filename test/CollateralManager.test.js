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

	describe('allows saving collateral of different types', async () => {

		it('allows saving erc20 collateral', async () => {
			// setup: mint to erc20, register it as currency, mint bond
			await erc20Instance.mint(accounts[0], 100);
			await erc20Instance.approve(instance.address, 100);
			let currencyEvent = await instance.addERC20Currency(erc20Instance.address).then(tx => getEvent(tx, 'CurrencyAdded'));
			let bondEvent = await instance.mintBond(bondBytes[0], bondBytes[1]).then(tx => getEvent(tx, 'Transfer'));
			// console.log(`Added Currency id: ${currencyEvent.id.toNumber()}`);
			// console.log(`Created Bond id: ${bondEvent.tokenId.toNumber()}`);
			//  associate some erc20 collateral
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
			//  associate some erc721 collateral
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
			//  associate some erc1155 collateral
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
			//  associate some erc1155 collateral
			let ev = await instance.addERC1155NFTCollateral(bondEvent.tokenId, currencyEvent.id, NFT_ID).then(tx => getEvent(tx, 'CollateralAdded'));
			assert.equal(ev.id.toNumber(), bondEvent.tokenId.toNumber());
			assert.equal(ev.collateralType, CURRENCY_TYPE.ERC1155NFT);
		});

	});
    
    
	describe('allows releasing collateral', async () => {

		const OPERATOR = accounts[0];

		let TOKEN_ID = 3; // should be treated like const
		let currencyEvent;
		let bondEvent;
		let collateralEvent;
		beforeEach(async () => {
			await erc1155Instance.mint(OPERATOR, TOKEN_ID, 100);
			await erc1155Instance.setApprovalForAll(instance.address, true);
			currencyEvent = await instance.addERC1155TokenCurrency(erc1155Instance.address, TOKEN_ID)
				.then(tx => getEvent(tx, 'CurrencyAdded'));
			bondEvent = await instance.mintBond(bondBytes[0], bondBytes[1])
				.then(tx => getEvent(tx, 'Transfer'));
			collateralEvent = await instance.addERC1155TokenCollateral(bondEvent.tokenId, currencyEvent.id, 100)
				.then(tx => getEvent(tx, 'CollateralAdded'));
		});

		afterEach(async () => {
			TOKEN_ID++;
		})

		it('fails when bond minter and bond isn\'t complete', async () => {
			let err = await getRevert(
				instance.releaseCollaterals([bondEvent.tokenId], [collateralEvent.id], OPERATOR));
			assert.include(err.reason.toLowerCase(), 'collateral');
			assert.include(err.reason.toLowerCase(), 'authorized');
		});

		it('succeeds when bond minter and bond is complete', async () => {
			await instance.forgiveBond(bondEvent.tokenId);
			let ev = await instance.releaseCollaterals([bondEvent.tokenId], [collateralEvent.id], OPERATOR)
				.then(tx => getEvent(tx, 'CollateralReleased'));
			assert.equal(ev.bondId.toNumber(), bondEvent.tokenId.toNumber());
			assert.equal(ev.collateralId.toNumber(), collateralEvent.id);
			assert.equal(ev.to, OPERATOR);
			// release collateral has proper side effects
			let numOwned = await erc1155Instance.balanceOf(OPERATOR, TOKEN_ID);
			assert.equal(numOwned.toNumber(), 100);
		});

		it('fails when bond owner and bond is active', async () => {
			let err = await getRevert(instance.releaseCollaterals([bondEvent.tokenId], [collateralEvent.id], OPERATOR));
			assert.include(err.reason.toLowerCase(), 'collateral');
			assert.include(err.reason.toLowerCase(), 'authorized');
		});

		it('succeeds when bond owner and bond is defaulted', async () => {
			await increaseTime(1000*60*60*24*256);
			let defaultEvent = await instance.callBond(bondEvent.tokenId)
				.then(tx => getEvent(tx, 'BondDefaulted'));
			assert.equal(defaultEvent.id.toNumber(), bondEvent.tokenId.toNumber());
			let ev = await instance.releaseCollaterals([bondEvent.tokenId], [collateralEvent.id], OPERATOR).then(tx => getEvent(tx, 'CollateralReleased'));
			assert.equal(ev.bondId.toNumber(), bondEvent.tokenId.toNumber());
			assert.equal(ev.collateralId.toNumber(), collateralEvent.id);
			assert.equal(ev.to, OPERATOR);
			// release collateral has proper side effects
			let numOwned = await erc1155Instance.balanceOf(OPERATOR, TOKEN_ID);
			assert.equal(numOwned.toNumber(), 100);
		});

		it.skip('has proper side effects for erc20');

		it.skip('has proper side effects for erc721');

		it.skip('has proper side effects for erc1155 tokens');

		it.skip('has proper side effects for erc1155 nfts');

		it('disallows releasing collaterals out of bounds', async () => {
			await instance.forgiveBond(bondEvent.tokenId);
			let err = await getRevert(instance.releaseCollaterals([bondEvent.tokenId], [10**6], OPERATOR));
			assert.include(err.message, "Index out of bounds");
		});

	});

});
