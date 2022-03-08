// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract LoanManagerExposed {

}

// import "../contracts/LoanManager.sol";

// contract LoanManagerExposed is LoanManager {
//     CollateralManager private _man = new CollateralManager();

//     constructor() LoanManager(address(_man)) {}

//     function createLoan(
//         uint16 _nPeriods,
//         uint32 _periodDuration,
//         uint128 _couponSize
//     ) external returns (uint256) {
//         return _createLoan(_nPeriods, _periodDuration, _couponSize);
//     }

//     function serviceLoan(
//         uint256 _id,
//         uint256 _with,
//         address _to
//     ) external {
//         _serviceLoan(_id, _with, _to);
//     }

//     function cancelLoan(uint256 _id) external {
//         _cancelLoan(_id);
//     }

//     function callLoan(uint256 _id) external {
//         _callLoan(_id);
//     }

//     function shiftTime(uint64 _time) external {
//         for (uint256 i = 0; i < loans.length; i++) {
//             loans[i].startTime -= _time;
//         }
//     }
// }
