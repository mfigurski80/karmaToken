// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0;
pragma abicoder v2;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/LoanManager.sol";

contract TestLoanManager {
    uint256 public constant initialBalance = 1000 wei;
    LoanManager loanManager = LoanManager(DeployedAddresses.LoanManager());

    // UTILITY FUNCTIONS

    function _getPeriodicLoan(uint256 id)
        internal
        view
        returns (PeriodicLoan memory)
    {
        PeriodicLoan memory l;
        (
            l.active,
            l.creditor,
            l.borrower,
            l.period,
            l.nextServiceTime,
            l.balance,
            l.minimumPayment
        ) = loanManager.loans(id);
        return l;
    }

    // TESTS

    function testCreatingLoan() public {
        uint256 id = loanManager._createLoan(
            block.timestamp + 7 days,
            1 days,
            70
        );
        Assert.equal(id, 0, "Ids should start at 0");
        // PeriodicLoan[] memory loans = loanManager.getLoans();
        // Assert.equal(loans.length, 1, "There should be one loan");

        PeriodicLoan memory l = _getPeriodicLoan(id);
        Assert.isTrue(l.active, "Loan should be active");
        Assert.equal(
            l.creditor,
            address(this),
            "Should be initially owned by creator"
        );
        Assert.equal(
            l.creditor,
            l.borrower,
            "Creditor and borrower should be the same initially"
        );
        Assert.equal(l.period, 1 days, "Period should be 1 day");
        Assert.equal(
            l.nextServiceTime,
            block.timestamp + 1 days,
            "Next service time should be 7 days from now"
        );
        Assert.equal(l.balance, 70, "Balance should be 70 initially");
        Assert.equal(l.minimumPayment, 10, "Payment should be 10 (70/7)");
    }

    function testServiceLoan() public {
        uint256 id = 0;
        payable(address(loanManager)).transfer(1000 wei);
        PeriodicLoan memory original = _getPeriodicLoan(id);

        loanManager._serviceLoan(id, 10);
        PeriodicLoan memory a = _getPeriodicLoan(id);
        Assert.equal(
            original.nextServiceTime + 1 days,
            a.nextServiceTime,
            "Proper servicing should increment the service time"
        );

        loanManager._serviceLoan(id, 5);
        PeriodicLoan memory b = _getPeriodicLoan(id);
        Assert.equal(
            a.nextServiceTime,
            b.nextServiceTime,
            "Insufficient servicing shouldn't increment the service time"
        );

        loanManager._serviceLoan(id, 5);
        PeriodicLoan memory c = _getPeriodicLoan(id);
        Assert.equal(
            b.nextServiceTime + 1 days,
            c.nextServiceTime,
            "Servicing can be split across transactions"
        );
    }

    receive() external payable {}
}
