const CurrencyManager = artifacts.require("CurrencyManager");
const BigNumber = require('bignumber.js');
const { getEvent, getRevert, CURRENCY_TYPE } = require('./utils');


contract("CurrencyManager", accounts => {
    let instance;

    beforeEach(async () => {
        instance = await CurrencyManager.new();
    });

    it('allows adding ERC20 and ERC721 currencies', async () => {
        let tx = await instance.addERC20Currency(accounts[0]);
        let ev = await getEvent(tx, 'CurrencyAdded');
        assert.equal(ev.id, 1, 'Id starts at 1 since 0 refers to ether');
        assert.equal(ev.currencyType, CURRENCY_TYPE.ERC20);
        assert.equal(ev.location, accounts[0]);
        assert.equal(ev.ERC1155Id, 0);

        tx = await instance.addERC721Currency(accounts[0]);
        ev = await getEvent(tx, 'CurrencyAdded');
        assert.equal(ev.id, 2);
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

        tx = await instance.addERC1155Currency(accounts[0]);
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
});