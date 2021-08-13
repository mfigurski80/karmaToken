// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./LoanManager.sol";

contract LoanToken is LoanManager, ERC721URIStorage {
    constructor() ERC721("PeriodicLoanToken", "PLT") {}

    /**
     * @dev Mint a new loan token with given information
     * @param maturity The maturity of the loan
     * @param period The period of the loan
     * @param totalBalance The total of service payments to the loan
     */
    function mintLoan(
        uint256 maturity,
        uint256 period,
        uint256 totalBalance
    ) external {
        // TODO: require collateral
        require(period >= 1 days, "LoanToken: Period must be at least 1 day");
        require(
            maturity - block.timestamp >= period,
            "LoanToken: Maturity must be at least one period after current block timestamp"
        );
        require(
            totalBalance > 0,
            "LoanToken: Total balance must be greater than 0"
        );
        uint256 id = _createLoan(maturity, period, totalBalance);
        _mint(msg.sender, id);
    }
}
