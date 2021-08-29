const LoanToken = artifacts.require('LoanToken');

const truffleAssert = require('truffle-assertions');

function getEvent(tx, event) {
    return new Promise((resolve, reject) => {
        truffleAssert.eventEmitted(tx, event, resolve);
    });
}

const TIME_UNIT = {
    DAY: 86400,
    WEEK: 604800,
    MONTH: 2592000,
};

contract('LoanToken', accounts => {
    let instance;
    const ownerAccount = accounts[0];

    before(async () => {
        instance = await LoanToken.new(accounts[accounts.length - 1], { from: ownerAccount });
    });


    it('should have a symbol and name', async () => {
        const symbol = await instance.symbol();
        assert.notEqual(symbol, '', 'Symbol was an empty string');
        const name = await instance.name();
        assert.notEqual(name, '', 'Name was an empty string');
    });

    it('should allow minting loans', async () => {
        let tx = await instance.mintLoan(Date.now() - TIME_UNIT.WEEK, TIME_UNIT.DAY, 100);
        let ev = await getEvent(tx, 'LoanCreated');
        assert.equal(ev.id, 0);

        const owner = await instance.ownerOf.call(ev.id);
        assert.equal(owner, ownerAccount, 'Loan owner was not set to creator by default');
    });

    it('allows loan beneficiary to be changed', async () => {
        let tx = await instance.mintLoan(Date.now() - TIME_UNIT.WEEK, TIME_UNIT.DAY, 100);
        let ev = await getEvent(tx, 'LoanCreated');
        await instance.updateLoanBeneficiary(ev.id, accounts[1]);

        const owner = await instance.ownerOf.call(ev.id);
        assert.equal(owner, ownerAccount, 'Loan owner changed when beneficiary was changed');

        const l = await instance.loans.call(ev.id);
        assert.equal(l.beneficiary, accounts[1], 'Loan beneficiary was not changed');
    });

    it('changes beneficiary with each transfer', async () => {
        let tx = await instance.mintLoan(Date.now() - TIME_UNIT.WEEK, TIME_UNIT.DAY, 100);
        let ev = await getEvent(tx, 'LoanCreated');
        await instance.transferFrom(ownerAccount, accounts[1], ev.id);

        const owner = await instance.ownerOf.call(ev.id);
        assert.equal(owner, accounts[1], 'Loan owner was not changed');

        const l = await instance.loans.call(ev.id);
        assert.equal(l.beneficiary, accounts[1], 'Loan beneficiary was not changed with transfer');
    });
});