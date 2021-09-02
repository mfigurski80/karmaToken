const LoanToken = artifacts.require('LoanToken');

const { TIME_UNIT, getEvent } = require('./utils');

contract('LoanToken', accounts => {
    let instance;
    const ownerAccount = accounts[0];

    before(async () => {
        instance = await LoanToken.new(accounts[accounts.length - 1], { from: ownerAccount });
    });

    it('should implement ERC165 and other interfaces', async () => {
        const erc165 = await instance.supportsInterface.call('0x01ffc9a7');
        assert.isTrue(erc165);
        const erc721 = await instance.supportsInterface.call('0x80ac58cd');
        assert.isTrue(erc721);
        const nullInterface = await instance.supportsInterface.call('0xffffffff');
        assert.isFalse(nullInterface);
    });

    it('should have a symbol and name', async () => {
        const symbol = await instance.symbol();
        assert.notEqual(symbol, '', 'Symbol was an empty string');
        const name = await instance.name();
        assert.notEqual(name, '', 'Name was an empty string');
    });

    it('should allow minting loans', async () => {
        let tx = await instance.mintLoan(Date.now() + TIME_UNIT.WEEK, TIME_UNIT.DAY, 100);
        let ev = await getEvent(tx, 'LoanCreated');
        assert.equal(ev.id, 0);

        const owner = await instance.ownerOf.call(ev.id);
        assert.equal(owner, ownerAccount, 'Loan owner was not set to creator by default');

        const balance = await instance.balanceOf.call(ownerAccount);
        assert.equal(balance.toNumber(), 1, 'Balance did not increase when minting token');

        const loan = await instance.loans.call(ev.id);
        assert.isTrue(loan.active, 'Loan was not marked as active by default');
        assert.equal(loan.balance.toNumber(), 100, 'Loan balance was not set to mint parameter');
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