const CurrencyManager = artifacts.require("CurrencyManager");

const { getEvent, getRevert } = require('./utils');


contract("CurrencyManager", accounts => {
    let instance;

    beforeEach(async () => {
        instance = await CurrencyManager.new();
    });

    it('allows adding new currencies', async () => {
        let tx = await instance.addCurrency(0, accounts[0]);
        let ev = await getEvent(tx, 'CurrencyAdded');
        assert.equal(ev.id.toNumber(), 0);
        assert.equal(ev.currencyType.toNumber(), 0);
        assert.equal(ev.location, accounts[0]);
    });

    it('exposes existing currencies', async () => {
        await instance.addCurrency(0, accounts[0]);
        let c = await instance.currencies(0);
        assert.equal(c.currencyType.toNumber(), 0);
        assert.equal(c.location, accounts[0]);
    });
});