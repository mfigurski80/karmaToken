const MonetizedLoanNFT = artifacts.require('MonetizedLoanNFT');

const { getEvent, getRevert, TIME_UNIT } = require('./utils');

contract('MonetizedLoanNFT', accounts => {
    let instance;
    const ownerAccount = accounts[0];
    const foreignAccount = accounts[1];

    beforeEach(async () => {
        // instance = await MonetizedLoanNFT.deployed();
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
        let tx = await instance.setMintFee(666, { from: ownerAccount });
        let ev = await getEvent(tx, 'FeeChanged');
        assert.isTrue(ev.isMint);
        assert.equal(ev.newFee.toNumber(), 666);

        tx = await instance.setServiceFee(666, { from: ownerAccount });
        ev = await getEvent(tx, 'FeeChanged');
        assert.isFalse(ev.isMint);
        assert.equal(ev.newFee.toNumber(), 666);
    });

    it('blocks non-owners from updating fees', async () => {
        let err = await getRevert(() => instance.setMintFee(10, { from: foreignAccount }));
        assert.include(err.message, 'not the owner');
    });

    it('applies mint fee when minting', async () => {
        let fee = await instance.mintFee.call();
        assert.notEqual(fee, 0, "Mint fee has defaulted to 0");
        let tx = await instance.mintLoan(
            Math.floor(Date.now()/1000) + TIME_UNIT.WEEK,
            TIME_UNIT.DAY,
            70,
            { from: ownerAccount, value: fee }
        );
        let ev = await getEvent(tx, 'LoanCreated');
        assert.equal(ev.id.toNumber(), 0, 'New contract is not first in position');
        assert.equal(ev.creator, ownerAccount, 'Creator is set in new loan');
        assert.equal(ev.amount.toNumber(), 70, 'Amount is set in new loan');
        // now try without fee
        err = await getRevert(() => instance.mintLoan(
            Math.floor(Date.now()/1000) + TIME_UNIT.WEEK,
            TIME_UNIT.DAY,
            70,
            { from: ownerAccount }
        ));
        assert.include(err.message, 'mint fee');
    });

    it('applies service fee when servicing', async () => {
        let mintFee = await instance.mintFee.call();
        let tx = await instance.mintLoan(
            Math.floor(Date.now()/1000) + TIME_UNIT.WEEK,
            TIME_UNIT.DAY,
            70,
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
        err = await getRevert(() => instance.serviceLoan(id, { from: ownerAccount, value: 10 }))
            .catch(err => assert.fail('service payment with no fee accepted'));
        assert.include(err.message, 'service fee', `Got wrong error: \n(${err.message})\n`);
    });
   
});