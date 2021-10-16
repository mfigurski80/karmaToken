const UpgradeableDelegate = artifacts.require('UpgradeableDelegate');

const { getRevert, increaseTime } = require('./utils');


contract('UpgradeableDelegate', accounts => {
    let instance;
    const owner = accounts[0];

    before(async () => {
        instance = await UpgradeableDelegate.new();
    });

    it('has public ref and refChange variables', async () => {
        let r = await instance.ref();
        assert.equal(r, 0);
        r = await instance.refChange();
        assert.equal(r, 0);
    });

    it('allows owner to submit change', async () => {
        await instance.submitChange(accounts[1], {from: owner});
        let r = await instance.refChange();
        assert.notEqual(r, 0);
    });

    it('allows one to implement change', async () => {
        await instance.submitChange(accounts[1], {from: owner});
        let err = await getRevert(instance.implementChange());
        assert.include(err.message.toLowerCase(), 'time');
        await increaseTime(60 * 60 * 24 * 31);
        try {
            await instance.implementChange();
        } catch (err) {
            assert.fail('Failed to implement change');
        }
        let r = await instance.ref();
        assert.equal(r, accounts[1]);
    });
})