const LBondReader = artifacts.require('LBondReader');
const BondData = artifacts.require('BondData');

contract('BondData', function(accounts) {
    let libraryInstance;
    let instance;
    
    const alphaBytes = '0x01ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff';
    const betaBytes = '0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff';

    before(async () => {
        libraryInstance = await LBondReader.new();
        BondData.link(libraryInstance);
    });

    beforeEach(async () => {
        instance = await BondData.new();
    });

    it('allows storing bond bytes', async () => {
        const res = await instance.addBond.call(alphaBytes, betaBytes);
        assert.equal(res.toNumber(), 0, 'Initial index is 0');
    });

    it('exposes data bytes', async () => {
        await instance.addBond(alphaBytes, betaBytes);
        let r = await instance.bonds(0);
        assert.equal(r, alphaBytes);
        r = await instance.bonds(1);
        assert.equal(r, betaBytes);
    });

    it('allows getting bond bytes', async () => {
        await instance.addBond(alphaBytes, betaBytes);
        let r = await instance.getBondBytes(0);
        assert.equal(r[0], alphaBytes);
        assert.equal(r[1], betaBytes);
    });

    it('extrapolates bond object from data', async () => {
        await instance.addBond(alphaBytes, betaBytes);
        let r = await instance.getBond(0);
        let check = await libraryInstance.readBeneficiary(betaBytes);
        assert.equal(r.beneficiary, check);
        check = await libraryInstance.readMinter(betaBytes);
        assert.equal(r.minter, check);
    });

    it('lets us write to either slot independently', async () => {
        await instance.addBond(alphaBytes, betaBytes);
        await instance.writeBondAlpha(0, betaBytes);
        await instance.writeBondBeta(0, alphaBytes);
        let check = await instance.getBondBytes(0);
        assert.equal(check[0], betaBytes);
        assert.equal(check[1], alphaBytes);
    })

});