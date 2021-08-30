const MonetizedLoanNFT = artifacts.require('MonetizedLoanNFT');

const { getEvent, getRevert } = require('./utils');

contract('MonetizedLoanNFT', accounts => {
    let instance;
    const ownerAccount = accounts[0];
    const foreignAccount = accounts[1];

    before(async () => {
        instance = await MonetizedLoanNFT.new(accounts[accounts.length - 1], { from: ownerAccount });
    });

    it('should be ownable', async () => {
        assert.equal(await instance.owner.call(), ownerAccount); 
    });

    it('should have visible mint + service fees', async () => {
        assert.exists(await instance.mintFee.call());
        assert.exists(await instance.serviceFee.call());
    });

    it('allows owner to update fees', async () => {
        let tx = await instance.setMintFee(10, { from: ownerAccount });
        let ev = await getEvent(tx, 'FeeChanged');
        assert.isTrue(ev.isMint);
        assert.equal(ev.newFee, 10);

        tx = await instance.setServiceFee(10, { from: ownerAccount });
        ev = await getEvent(tx, 'FeeChanged');
        assert.isFalse(ev.isMint);
        assert.equal(ev.newFee, 10);
    });

    it('blocks non-owners from updating fees', async () => {
        let err = await getRevert(() => instance.setMintFee(10, { from: foreignAccount }));
        assert.include(err.message, 'not the owner');
    });
   
});