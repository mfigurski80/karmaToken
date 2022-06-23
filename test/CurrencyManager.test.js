const CurrencyManager = artifacts.require("CurrencyManagerExposed");
const ERC20Exposed = artifacts.require("ERC20Exposed");
const ERC721Exposed = artifacts.require("ERC721Exposed");
const ERC1155Exposed = artifacts.require("ERC1155Exposed");

const BigNumber = require('bignumber.js');
const { getEvent, getEvents, getRevert, CURRENCY_TYPE } = require('./utils');


contract("CurrencyManager", accounts => {
    let instance;

    beforeEach(async () => {
        instance = await CurrencyManager.new();
    });

    it('allows adding ERC20 currencies', async () => {
        let tx = await instance.addERC20Currency(accounts[0]);
        let ev = await getEvent(tx, 'CurrencyAdded');
        assert.equal(ev.id, 1, 'Id starts at 1 since 0 refers to ether');
        assert.equal(ev.currencyType, CURRENCY_TYPE.ERC20);
        assert.equal(ev.location, accounts[0]);
        assert.equal(ev.ERC1155Id, 0);
    });

    it('allows adding ERC721 currencies', async () => {
        let tx = await instance.addERC721Currency(accounts[0]);
        let ev = await getEvent(tx, 'CurrencyAdded');
        assert.equal(ev.id, 1);
        assert.equal(ev.currencyType, CURRENCY_TYPE.ERC721);
        assert.equal(ev.location, accounts[0]);
        assert.equal(ev.ERC1155Id, 0);
    });

    it('allows ERC1155 currencies', async () => {
        tx = await instance.addERC1155TokenCurrency(accounts[0], 1);
        let ev = await getEvent(tx, 'CurrencyAdded');
        assert.equal(ev.id, 1);
        assert.equal(ev.currencyType, CURRENCY_TYPE.ERC1155Token);
        assert.equal(ev.location, accounts[0]);
        assert.equal(ev.ERC1155Id, 1);

        tx = await instance.addERC1155NFTCurrency(accounts[0]);
        ev = await getEvent(tx, 'CurrencyAdded');
        assert.equal(ev.id, 2);
        assert.equal(ev.currencyType, CURRENCY_TYPE.ERC1155NFT);
        assert.equal(ev.location, accounts[0]);
        assert.equal(ev.ERC1155Id, 0);
    });

    it('handles large currencyIds efficiently', async () => {
        let n = BigNumber(2).pow(256).minus(1);
        let tx = await instance.addERC1155TokenCurrency(accounts[0], n);
        let ev = await getEvent(tx, 'CurrencyAdded');
        assert.equal(BigNumber(ev.ERC1155Id).toString(), n.toString());
    })

    it('exposes existing currencies', async () => {
        await instance.addERC20Currency(accounts[0]);
        let c = await instance.currencies(1);
        assert.equal(c.currencyType, CURRENCY_TYPE.ERC20);
        assert.equal(c.location, accounts[0]);
    });

    it('has Ether currency at index 0', async () => {
        let c = await instance.currencies(0);
        assert.equal(c.currencyType, CURRENCY_TYPE.ETHER);
    });

    describe('can transfer a generic currency between accounts', async () => {

        it('can transfer ERC20', async () => {
            const COUNT = 100;
            const erc20Instance = await ERC20Exposed.new();
            await erc20Instance.mint(instance.address, COUNT);
            let balance = await erc20Instance.balanceOf(instance.address);
            assert.equal(balance, COUNT);

            const { id } = await instance.addERC20Currency(erc20Instance.address)
                .then(tx => getEvent(tx, 'CurrencyAdded'));
            await instance.transferGenericCurrency(id, instance.address, accounts[0], COUNT, 0x0);

            balance = await erc20Instance.balanceOf(accounts[0]);
            assert.equal(balance, COUNT);
        });

        it('can transfer ERC721', async () => {
            const ID = 100;
            const erc721Instance = await ERC721Exposed.new("Test", "Test", "Test");
            await erc721Instance.mint(accounts[0], ID);
            await erc721Instance.setApprovalForAll(instance.address, true);
            let owner = await erc721Instance.ownerOf(ID);
            assert.equal(owner, accounts[0]);

            const { id } = await instance.addERC721Currency(erc721Instance.address)
                .then(tx => getEvent(tx, 'CurrencyAdded'));
            await instance.transferGenericCurrency(id, accounts[0], accounts[1], ID, 0x0);

            owner = await erc721Instance.ownerOf(ID);
            assert.equal(owner, accounts[1]);
        });

        it('can transfer ERC1155 Tokens', async () => {
            const ID = 10;
            const COUNT = 100;
            const erc1155Instance = await ERC1155Exposed.new();
            await erc1155Instance.mint(accounts[0], ID, COUNT);
            await erc1155Instance.setApprovalForAll(instance.address, true);
            let balance = await erc1155Instance.balanceOf(accounts[0], ID);
            assert.equal(balance, COUNT);

            const { id } = await instance.addERC1155TokenCurrency(erc1155Instance.address, ID)
                .then(tx => getEvent(tx, 'CurrencyAdded'));
            await instance.transferGenericCurrency(id, accounts[0], accounts[1], COUNT, 0x0);

            balance = await erc1155Instance.balanceOf(accounts[1], ID);
            assert.equal(balance, COUNT);
        });

        it('can transfer ERC1155 NFTs', async () => {
            const ID = 20;
            const erc1155Instance = await ERC1155Exposed.new();
            await erc1155Instance.mint(accounts[0], ID, 1);
            await erc1155Instance.setApprovalForAll(instance.address, true);
            let balance = await erc1155Instance.balanceOf(accounts[0], ID);
            assert.equal(balance, 1);

            const { id } = await instance.addERC1155NFTCurrency(erc1155Instance.address)
                .then(tx => getEvent(tx, 'CurrencyAdded'));
            await instance.transferGenericCurrency(id, accounts[0], accounts[1], ID, 0x0);

            balance = await erc1155Instance.balanceOf(accounts[1], ID);
            assert.equal(balance, 1);
        })

    })
});