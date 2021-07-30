// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0;

import "./CollateralStruct.sol";

struct PeriodicLoan {
    bool active; // whether contract is still active or completed
    address creditor; // 'owner' of contract
    address borrower; // 'minter' of contract
    uint256 period; // how often payments required
    uint256 nextServiceTime; // next payment required
    uint256 balance; // remaining payment amount
    uint256 minimumPayment; // minimum payment amount
    Collateral[] collateral; // loan security
}
