const LoanToken = artifacts.require('LoanToken');

const { TIME_UNIT, now, getEvent, getRevert } = require('./utils');

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
        let tx = await instance.mintLoan(7, TIME_UNIT.DAY, 10);
        let ev = await getEvent(tx, 'LoanCreated');
        assert.equal(ev.id, 0);

        const owner = await instance.ownerOf.call(ev.id);
        assert.equal(owner, ownerAccount, 'Loan owner was not set to creator by default');

        const balance = await instance.balanceOf.call(ownerAccount);
        assert.equal(balance.toNumber(), 1, 'Balance did not increase when minting token');

        const loan = await instance.loans.call(ev.id);
        assert.isFalse(loan.failed, 'Loan should not be marked as failed');
        assert.equal(loan.couponSize.toNumber(), 10, 'Loan coupon was not set to mint parameter');
    });

    it('shouldn\'t allow minting tokens with bad parameters', async () => {
        let err = await getRevert(instance.mintLoan(0, TIME_UNIT.DAY, 10));
        // assert.include(err.message.toLowerCase(), 'matur', 'Error should be related to maturity time');
        err = await getRevert(instance.mintLoan(7, 10, 10));
        assert.include(err.message.toLowerCase(), 'period', 'Error should be related to period');
    });

});