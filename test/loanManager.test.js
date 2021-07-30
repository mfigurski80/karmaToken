const LoanManager = artifacts.require('LoanManager.sol');
const truffleAssert = require('truffle-assertions');

const time = require('../utils/time');


contract('LoanManager', accounts => {
    let loanManager;
    let account = accounts[0];

    before(async() => {
        loanManager = await LoanManager.deployed();
    });

    it('deploys properly', async () => {
        assert.exists(loanManager);
    });

    describe('creating a loan', async () => {

        it('creates a new loan with proper data', async () => {
            let res = await loanManager._createLoan(
                Date.now() + time.week, time.day, 0);
            truffleAssert.eventEmitted(res, 'LoanCreated');
            console.log(res);
            // const loan = await loanManager.loans(1);
            // console.log(loan.nextServiceTime);
        });

    });
    
});