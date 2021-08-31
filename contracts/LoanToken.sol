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
     * @param maturity The maturity of the loan
     * @param period The period of the loan
     * @param totalBalance The total of service payments to the loan
     */
    function mintLoan(
        uint256 maturity,
        uint256 period,
        uint256 totalBalance
    ) public payable virtual returns (uint256) {
        require(
            period >= 900,
            "LoanToken: Period must be at least 900 seconds"
        );
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
        return id;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        if (from == address(0) || to == address(0)) return;
        loans[tokenId].beneficiary = to;
    }

    function updateLoanBeneficiary(uint256 id, address newBeneficiary)
        external
        onlyApprovedOrOwner(id)
    {
        _updateBeneficiary(id, newBeneficiary);
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
        _serviceLoan(id, msg.value);
    }

    function cancelLoan(uint256 id) public onlyApprovedOrOwner(id) {
        _cancelLoan(id);
    }

    function callLoan(uint256 id)
        public
        onlyApprovedOrOwner(id)
        returns (bool)
    {
        return _callLoan(id);
    }
}
