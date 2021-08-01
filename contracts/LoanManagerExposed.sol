// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0;

import "./LoanManager.sol";

contract LoanManagerExposed is LoanManager {
    function createLoan(
        uint256 _maturity,
        uint256 _period,
        uint256 _totalBalance
    ) external returns (uint256) {
        return _createLoan(_maturity, _period, _totalBalance);
    }

    function serviceLoan(uint256 _id, uint256 _with) external {
        _serviceLoan(_id, _with);
    }

    function cancelLoan(uint256 _id) external {
        _cancelLoan(_id);
    }

    function callLoan(uint256 _id) external returns (bool) {
        return _callLoan(_id);
    }

    function _shiftTime(uint256 _time) external {
        for (uint256 i = 0; i < loans.length; i++) {
            loans[i].nextServiceTime -= _time;
        }
    }
}
