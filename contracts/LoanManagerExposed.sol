// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0;
pragma abicoder v2;

import "./LoanManager.sol";

contract LoanManagerExposed is LoanManager {
    function getLoans() public view returns (PeriodicLoan[] memory) {
        return loans;
    }

    function createLoan(
        uint256 _dueDate,
        uint256 _period,
        uint256 _totalBalance
    ) public returns (uint256) {
        return _createLoan(_dueDate, _period, _totalBalance);
    }
}
