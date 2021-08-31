// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./LoanToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MonetizedLoanNFT is LoanToken, Ownable {
    uint256 public mintFee = .001 ether; // .001 ~ $3
    uint256 public serviceFee = 1_000; // percentage, divided by 1,000,000 (so .1% default)

    event FeeChanged(bool isMint, uint256 newFee);

    constructor(address manager) LoanToken(manager) {}

    /**
     * @dev Sets initial mint fee (when minter is creating). Only
     *  callable by owner.
     * @param newFee New Fee to apply to all mints
     */
    function setMintFee(uint256 newFee) external onlyOwner {
        mintFee = newFee;
        emit FeeChanged(true, newFee);
    }

    /**
     * @dev Sets service fee (when minter is paying). Only
     * callable by owner.
     * @param newFee New Fee to bite out of service payments.
     */
    function setServiceFee(uint256 newFee) external onlyOwner {
        serviceFee = newFee;
        emit FeeChanged(false, newFee);
    }

    // OVERRIDES

    /**
     * @dev Ensure user pays minting fee when minting
     */
    function mintLoan(
        uint256 maturity,
        uint256 period,
        uint256 totalBalance
    ) public payable override returns (uint256) {
        require(
            msg.value >= mintFee,
            "MonetizedLoanNFT: ether sent does not cover mint fee"
        );
        return super.mintLoan(maturity, period, totalBalance);
    }

    /**
     * @dev Ensure user pays service fee when servicing, but be aware value
     *  might be different based on what they're doing
     */
    function serviceLoan(uint256 id) public payable override {
        uint256 fee = (msg.value * serviceFee) / 1_000_000;
        if (fee == 0) fee = 1;
        uint256 trueValue = msg.value - fee;
        require(
            trueValue >= loans[id].minimumPayment ||
                trueValue >= loans[id].balance,
            "MonetizedLoanNFT: ether sent cannot cover service fee and minimum payment"
        );
        super.serviceLoan(id);
    }
}
