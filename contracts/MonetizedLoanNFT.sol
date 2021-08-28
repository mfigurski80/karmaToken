// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./LoanToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MonetizedLoanNFT is LoanToken, Ownable {
    uint256 public saleFee = .001 ether;
    uint256 public resaleFee = .003 ether;

    constructor(address manager) LoanToken(manager) {}

    /**
     * @dev Sets initial sale fee (when minter is transfering). Only
     *  callable by owner.
     * @param newFee New Fee to apply to all initial sales
     */
    function setSaleFee(uint256 newFee) external onlyOwner {
        saleFee = newFee;
    }

    /**
     * @dev Sets secondary-maker sale fee (when creditor is
     *  transfering). Only callable by owner.
     * @param newFee New Fee to apply to all secondary-market sales.
     */
    function setResaleFee(uint256 newFee) external onlyOwner {
        resaleFee = newFee;
    }
}
