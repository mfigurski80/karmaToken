// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma abicoder v2;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/LoanManagerExposed.sol";

import "./Utility.sol";

contract TestLoanManager is Utility {
    uint256 public constant initialBalance = 10000 wei; // NOTE: increase as you see fit
    LoanManagerExposed loanManager;

    function beforeEach() public {
        loanManager = new LoanManagerExposed();
    }

    // TESTS

    function testCreatingLoan() public {
        uint256 id = loanManager.createLoan(
            block.timestamp + 10 days,
            1 days,
            100
        );
        Assert.equal(id, 0, "Ids should start at 0");
        // PeriodicLoan[] memory loans = loanManager.getLoans();
        // Assert.equal(loans.length, 1, "There should be one loan");

        PeriodicLoan memory l = _getPeriodicLoan(id, loanManager);
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
        Assert.equal(l.balance, 100, "Balance should be 70 initially");
        Assert.equal(l.minimumPayment, 10, "Payment should be 10 (100/10)");
    }

    function testServiceLoan() public {
        // setup
        payable(address(loanManager)).transfer(100 wei);
        uint256 id = loanManager.createLoan(
            block.timestamp + 10 days,
            1 days,
            100
        );
        PeriodicLoan memory original = _getPeriodicLoan(id, loanManager);

        loanManager.serviceLoan(id, 10);
        PeriodicLoan memory a = _getPeriodicLoan(id, loanManager);
        Assert.equal(
            original.nextServiceTime + 1 days,
            a.nextServiceTime,
            "Proper servicing should increment the service time"
        );

        loanManager.serviceLoan(id, 5);
        PeriodicLoan memory b = _getPeriodicLoan(id, loanManager);
        Assert.equal(
            a.nextServiceTime,
            b.nextServiceTime,
            "Insufficient servicing shouldn't increment the service time"
        );

        loanManager.serviceLoan(id, 5);
        PeriodicLoan memory c = _getPeriodicLoan(id, loanManager);
        Assert.equal(
            b.nextServiceTime + 1 days,
            c.nextServiceTime,
            "Servicing can be split across transactions to increment service time"
        );

        loanManager.serviceLoan(id, 80);
        PeriodicLoan memory d = _getPeriodicLoan(id, loanManager);
        Assert.isFalse(
            d.active,
            "Full servicing should result in closure of loan"
        );
    }

    function testCancelLoan() public {
        uint256 id = loanManager.createLoan(
            block.timestamp + 10 days,
            1 days,
            100
        );
        loanManager.cancelLoan(id);

        PeriodicLoan memory l = _getPeriodicLoan(id, loanManager);
        Assert.isFalse(l.active, "Cancellation should close loan");

        // TODO: expect failture to service loan
        // loanManager.serviceLoan(id, 5);
    }

    function testCallLoan() public {
        uint256 id = loanManager.createLoan(
            block.timestamp + 1 days,
            1 days,
            100
        );
        bool hasDefaulted = loanManager.callLoan(id);
        Assert.isFalse(hasDefaulted, "Cannot call if not yet defaulted");

        loanManager._shiftTime(2 days);
        hasDefaulted = loanManager.callLoan(id);
        Assert.isTrue(hasDefaulted, "Can call if defaulted");
    }

    receive() external payable {}
}
