// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma abicoder v2;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "./LoanManagerExposed.sol";

import "./Utility.sol";

contract TestLoanManager is Utility {
    uint256 public constant initialBalance = 10000 wei; // NOTE: increase as you see fit
    LoanManagerExposed loanManager;
    address payable OWNER = payable(address(1));

    function beforeEach() public {
        loanManager = new LoanManagerExposed();
    }

    // TESTS

    function testCreatingLoan() public {
        uint256 id = loanManager.createLoan(10, 1 days, 10);
        Assert.equal(id, 0, "Ids should start at 0");
        // PeriodicLoan[] memory loans = loanManager.getLoans();
        // Assert.equal(loans.length, 1, "There should be one loan");

        PeriodicLoan memory l = _getPeriodicLoan(id, loanManager);
        Assert.isFalse(l.failed, "Loan should not be failed");
        Assert.equal(
            l.minter,
            address(this),
            "Minter should be marked as contract borrower"
        );
        Assert.equal(l.periodDuration, 1 days, "Period should be 1 day");
        Assert.equal(
            l.curPeriod,
            0,
            "Loan should not have any service payments yet"
        );
        Assert.equal(l.nPeriods, 10, "Should have 10 total periods");
        Assert.equal(l.couponSize, 10, "Coupon should be set to 10");
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

        try loanManager.serviceLoan(id, 5) {
            Assert.equal(
                true,
                false,
                "Partial servicing should revert/fail transaction"
            );
        } catch (bytes memory) {
            // good revert, works
        }
        PeriodicLoan memory b = _getPeriodicLoan(id, loanManager);
        Assert.equal(
            a.nextServiceTime,
            b.nextServiceTime,
            "Failed servicing shouldn't increment the service time"
        );

        loanManager.serviceLoan(id, 90);
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
