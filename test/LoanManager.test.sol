// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma abicoder v2;

contract TestLoanManager {

}

// import "truffle/Assert.sol";
// import "truffle/DeployedAddresses.sol";
// import "./LoanManagerExposed.sol";

// import "./Utility.sol";

// contract TestLoanManager is Utility {
//     uint256 public constant initialBalance = 10000 wei; // NOTE: increase as you see fit
//     LoanManagerExposed loanManager;
//     address payable OWNER = payable(address(1));

//     function beforeEach() public {
//         loanManager = new LoanManagerExposed();
//     }

//     // TESTS

//     function testCreatingLoan() public {
//         uint256 id = loanManager.createLoan(10, 1 days, 10);
//         Assert.equal(id, 0, "Ids should start at 0");
//         // PeriodicLoan[] memory loans = loanManager.getLoans();
//         // Assert.equal(loans.length, 1, "There should be one loan");

//         PeriodicLoan memory l = _getPeriodicLoan(id, loanManager);
//         Assert.isFalse(l.failed, "Loan should not be failed");
//         Assert.equal(
//             l.minter,
//             address(this),
//             "Minter should be marked as contract borrower"
//         );
//         Assert.equal(l.periodDuration, 1 days, "Period should be 1 day");
//         Assert.equal(
//             l.curPeriod,
//             0,
//             "Loan should not have any service payments yet"
//         );
//         Assert.equal(l.nPeriods, 10, "Should have 10 total periods");
//         Assert.equal(l.couponSize, 10, "Coupon should be set to 10");
//     }

//     function testServiceLoan() public {
//         // setup
//         payable(address(loanManager)).transfer(100 wei);
//         uint256 id = loanManager.createLoan(10, 1 days, 10);
//         PeriodicLoan memory original = _getPeriodicLoan(id, loanManager);

//         loanManager.serviceLoan(id, 10, OWNER);
//         PeriodicLoan memory a = _getPeriodicLoan(id, loanManager);
//         Assert.equal(
//             original.curPeriod + 1,
//             a.curPeriod,
//             "Proper servicing should increment the current period"
//         );

//         try loanManager.serviceLoan(id, 5, OWNER) {
//             Assert.equal(
//                 true,
//                 false,
//                 "Partial servicing should revert/fail transaction"
//             );
//         } catch (bytes memory) {
//             // good revert, works
//         }
//         PeriodicLoan memory b = _getPeriodicLoan(id, loanManager);
//         Assert.equal(
//             a.curPeriod,
//             b.curPeriod,
//             "Failed servicing shouldn't increment the current period"
//         );

//         loanManager.serviceLoan(id, 90, OWNER);
//         PeriodicLoan memory d = _getPeriodicLoan(id, loanManager);
//         Assert.equal(
//             d.curPeriod,
//             d.nPeriods,
//             "Full servicing should result in closure of loan"
//         );
//         Assert.isFalse(
//             d.failed,
//             "Should not be marked as failed after closure"
//         );
//     }

//     function testCancelLoan() public {
//         uint256 id = loanManager.createLoan(10, 1 days, 10);
//         loanManager.cancelLoan(id);

//         PeriodicLoan memory l = _getPeriodicLoan(id, loanManager);
//         Assert.equal(l.curPeriod, l.nPeriods, "Cancellation should close loan");
//         Assert.isFalse(
//             l.failed,
//             "Should not be marked as failed after cancellation"
//         );
//     }

//     function testCallLoan() public {
//         uint256 id = loanManager.createLoan(10, 1 days, 10);
//         try loanManager.callLoan(id) {
//             Assert.isFalse(true, "Cannot call if not yet defaulted");
//         } catch (bytes memory) {}

//         loanManager.shiftTime(2 days);
//         try loanManager.callLoan(id) {} catch (bytes memory) {
//             Assert.isFalse(true, "Can call if defaulted");
//         }
//     }

//     receive() external payable {}
// }
