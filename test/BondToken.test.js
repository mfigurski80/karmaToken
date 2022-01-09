const LBondManager = artifacts.require('LBondManager');
const BondToken = artifacts.require('BondToken');

const { getEvent, getRevert } = require('./utils');

contract('BondToken', accounts => {
    let libraryInstance;
    let instance;
    const args = { name: 'Test Token', symbol: 'TST', uri: 'http://localhost' };
    const owner = accounts[0];
    const bytes = [
        '0x01ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff',
        `0xffffffffffffffffffffffff${owner.substring(2).toLowerCase()}`
    ];

    before(async () => {
        libraryInstance = await LBondManager.new();
        BondToken.link(libraryInstance);
    });

    beforeEach(async () => {
        instance = await BondToken.new(args.name, args.symbol, args.uri);
    });

    it('allows minting new bonds', async () => {
        let tx = await instance.mintBond(bytes[0], bytes[1]);
        let ev = await getEvent(tx, 'Transfer');
        assert.equal(ev.from, 0x0);
        assert.equal(ev.to, owner);
        assert.equal(ev.tokenId, 0);
    });

    it('disallows minting bonds with bad minter data', async () => {
        let err = await getRevert(instance.mintBond(bytes[0], bytes[0]));
        assert.include(err.message, 'minter');
    });

    it('correctly mints multiple bonds in a row', async () => {
        for (let i = 0; i < 4; i++) {
            let tx = await instance.mintBond(bytes[0], bytes[1]);
            let ev = await getEvent(tx, 'Transfer');
            assert.equal(ev.from, 0x0);
            assert.equal(ev.to, owner);
            assert.equal(ev.tokenId, i);
        }
    });

    it('exposes bond data bytes', async () => {
        await instance.mintBond(bytes[0], bytes[1]);
        let alp = await instance.bonds(0);
        assert.equal(alp, bytes[0]);
        let bet = await instance.bonds(1);
        assert.equal(bet, bytes[1]);
    });

    it('allows getting full formatted bond', async () => {
        await instance.mintBond(bytes[0], bytes[1]);
        let b = await instance.getBond(0);
        assert.equal(b.minter, owner);
    });

    it.skip('allows updating the bond beneficiary', async () => {
        await instance.mintBond(bytes[0], bytes[1]);
        let b = await instance.getBond(0);
        assert.notEqual(b.beneficiary, owner);

        let tx = await instance.updateBeneficiary(0, owner);
        let ev = await getEvent(tx, 'BeneficiaryChange');
        assert.equal(ev.id, 0);
        assert.equal(ev.beneficiary, owner);
        b = await instance.getBond(0);
        assert.equal(b.beneficiary, owner);
    });
});