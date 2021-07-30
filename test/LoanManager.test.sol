// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0;
pragma abicoder v2;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/LoanManager.sol";

contract TestLoanManager {
    LoanManager loanManager = LoanManager(DeployedAddresses.LoanManager());

    function testCreatingLoan() public {
        uint256 id = loanManager._createLoan(
            block.timestamp + 7 days,
            1 days,
            70
        );
        Assert.equal(id, 0, "Ids should start at 0");
        // PeriodicLoan[] memory loans = loanManager.getLoans();
        // Assert.equal(loans.length, 1, "There should be one loan");

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
        Assert.isTrue(l.active, "Loan should be active");
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
}
