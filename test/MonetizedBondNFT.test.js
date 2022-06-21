const MonetizedBondNFT = artifacts.require('MonetizedBondNFT');
const LBondManager = artifacts.require('LBondManager');

const { buildBondBytes, getEvent, getRevert, TIME_UNIT } = require('./utils');

contract('MonetizedLoanNFT', accounts => {
    let instance;
    let libraryInstance;
    
    const ownerAccount = accounts[0];
    const foreignAccount = accounts[1];
    const bytes = buildBondBytes({
        flag: false,
        currencyRef: 0,
        nPeriods: 10, curPeriod: 0,
        startTime: Date.now(), periodDuration: 60*60*24,
        couponSize: 1, faceValue: 2,
        beneficiary: ownerAccount, minter: ownerAccount,
    });

    before(async () => {
        libraryInstance = await LBondManager.new();
        MonetizedBondNFT.link(libraryInstance);
    });

    beforeEach(async () => {
        instance = await MonetizedBondNFT.new("Test", "Test", "Test", { from: ownerAccount });
    });

    it('should be ownable', async () => {
        assert.equal(await instance.owner.call(), ownerAccount); 
    });

    it('should have visible mint + service fees', async () => {
        assert.exists(await instance.mintFee.call());
        assert.exists(await instance.serviceFee.call());
    });

    it('allows owner to update fees', async () => {
        let tx = await instance.setMintFee(666, { from: ownerAccount });
        let ev = await getEvent(tx, 'MintFeeChanged');
        // assert.isTrue(ev.isMintFee);
        assert.equal(ev.newFee.toNumber(), 666);

        tx = await instance.setServiceFee(666, { from: ownerAccount });
        ev = await getEvent(tx, 'ServiceFeeChanged');
        // assert.isFalse(ev.isMintFee);
        assert.equal(ev.newFee.toNumber(), 666);
    });

    it('blocks non-owners from updating fees', async () => {
        let err = await getRevert(instance.setMintFee(10, { from: foreignAccount }));
        assert.include(err.message, 'not the owner');
    });

    it('applies mint fee when minting', async () => {
        let fee = await instance.mintFee.call();
        assert.notEqual(fee, 0, "Mint fee has defaulted to 0");
        let tx = await instance.mintBond(bytes[0], bytes[1],
            { from: ownerAccount, value: fee }
        );
        await getEvent(tx, 'Transfer');
        // now try without fee
        let err = await getRevert(instance.mintBond(bytes[0], bytes[1]));
        assert.include(err.message, 'mint fee');
    });

    it.skip('applies service fee when servicing', async () => {
        let mintFee = await instance.mintFee.call();
        let tx = await instance.mintLoan(
            7,
            TIME_UNIT.DAY,
            10,
            { from: ownerAccount, value: mintFee }
        );
        let { id } = await getEvent(tx, 'LoanCreated');

        let fee = await instance.serviceFee.call();
        const getServiceFee = (amount) => Math.ceil(amount + amount * fee / 1000000);
        tx = await instance.serviceLoan(id, { from: ownerAccount, value: getServiceFee(10) });
        let ev = await getEvent(tx, 'LoanServiced');
        assert.equal(ev.id.toNumber(), id.toNumber(), `Serviced loan id ${ev.id} is not the expected loan id ${id}`);
        assert.equal(ev.servicer, ownerAccount, `Loan servicer ${ev.servicer} is not actual servicer`);
        assert.equal(ev.amount.toNumber(), 10, 'Servicing fee is being included in servicing');
        // now try without fee
        err = await getRevert(instance.serviceLoan(id, { from: ownerAccount, value: 10 }))
            .catch(err => assert.fail('service payment with no fee accepted'));
        assert.include(err.message, 'service fee', `Got wrong error: \n(${err.message})\n`);
    });
   
});