// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./LoanManager.sol";

contract LoanToken is LoanManager, ERC721URIStorage {
    modifier onlyApprovedOrOwner(uint256 id) {
        require(
            _isApprovedOrOwner(msg.sender, id),
            "LoanToken: Caller must have access to this token"
        );
        _;
    }

    constructor(address manager)
        LoanManager(manager)
        ERC721("LOANOnANetwork", "LOAN")
    {}

    /**
     * @dev Mint a new loan token with given information. Payable to
     *  allow overriding to add mint fees
     * @param nPeriods The number of periods in the loan
     * @param periodDuration The duration of each period
     * @param couponSize How much wei each coupon payment will be
     */
    function mintLoan(
        uint16 nPeriods,
        uint32 periodDuration,
        uint128 couponSize
    ) public payable virtual returns (uint256) {
        require(
            periodDuration >= 900,
            "LoanToken: Period must be at least 900 seconds"
        );
        require(nPeriods > 0, "LoanToken: Must have at least one period");
        require(
            couponSize > 0,
            "LoanToken: COupon balance must be greater than 0"
        );

        uint256 id = _createLoan(nPeriods, periodDuration, couponSize);
        _mint(msg.sender, id);
        return id;
    }

    function addERC20Collateral(
        uint256 id,
        address tokenAddress,
        uint256 count
    ) external onlyCreator(id) {
        _reserveERC20Collateral(id, tokenAddress, count);
    }

    function addERC721Collateral(
        uint256 id,
        address nftContractAddress,
        uint256 nftId
    ) external onlyCreator(id) {
        _reserveERC721Collateral(id, nftContractAddress, nftId);
    }

    function serviceLoan(uint256 id) public payable virtual onlyCreator(id) {
        _serviceLoan(id, msg.value, ownerOf(id));
    }

    function cancelLoan(uint256 id) public onlyApprovedOrOwner(id) {
        _cancelLoan(id);
    }

    function callLoan(uint256 id) public onlyApprovedOrOwner(id) {
        _callLoan(id);
    }
}
