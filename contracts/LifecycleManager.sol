// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./BondToken.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/**
 * 🦓 Lifecycle Manager
 */
contract LifecycleManager is BondToken {
    using LBondManager for bytes32;

    event BondServiced(uint256 id, uint64 toPeriod);

    constructor(
        string memory name,
        string memory symbol,
        string memory uri
    )
        BondToken(name, symbol, uri) // solhint-disable-next-line no-empty-blocks
    {}

    /**
     * Internal function containing logic for updating bond
     * Returns referenced bond, with only alpha elements filled
     */
    function _serviceBond(uint256 id, uint256 amount)
        internal
        returns (Bond memory)
    {
        // read bond
        bytes32 alpha = bonds[id * 2];
        Bond memory b = alpha.fillBondFromAlpha(
            Bond(false, 0, 0, 0, 0, 0, 0, 0, address(0), address(0))
        );
        // Currency memory c = currencies[b.currencyRef];
        // figure out period change
        uint16 addedPeriods = uint16(amount / b.couponSize);
        require(
            addedPeriods > 0,
            "LifecycleManager: service payment insufficient"
        );
        b.curPeriod += addedPeriods;
        if (b.curPeriod > b.nPeriods) b.curPeriod = b.nPeriods;
        bonds[id * 2] = alpha.writeCurPeriod(b.curPeriod);
        // return currency type
        return b;
        // presumably:
        // calling function should check for matching currency
        // and pay bond holder whatever he is due in that currency
    }

    function serviceBondWithEther(uint256 id) public payable {
        // read bond
        Bond memory b = _serviceBond(id, msg.value);
        require(
            b.currencyRef == 0,
            "LifecycleManager: wrong servicing currency"
        );
        // pay beneficiary
        (bool success, ) = b.beneficiary.call{value: msg.value}("");
        require(success, "LifecycleManager: ether transaction failed");
        emit BondServiced(id, b.curPeriod);
    }

    function serviceBondWithERC20(uint256 id, uint256 amount) public payable {
        // read bond
        Bond memory b = _serviceBond(id, amount);
        Currency memory c = currencies[b.currencyRef];
        require(
            c.currencyType == 0,
            "LifecycleManager: wrong servicing currency"
        );
        // pay beneficiary
        bool success = IERC20(c.location).transferFrom(
            msg.sender,
            b.beneficiary,
            amount
        );
        require(success, "LifecycleManager: erc20 transaction failed");
        emit BondServiced(id, b.curPeriod);
    }

    function serviceBondWithERC721(uint256 id, uint256 tokenId) public payable {
        // read bond
        Bond memory b = _serviceBond(id, 1);
        Currency memory c = currencies[b.currencyRef];
        require(
            c.currencyType == 1,
            "LifecycleManager: wrong servicing currency"
        );
        // pay beneficiary
        IERC721(c.location).safeTransferFrom(
            msg.sender,
            b.beneficiary,
            tokenId
        );
        emit BondServiced(id, b.curPeriod);
    }

    function serviceBondWithERC1155Token(uint256 id, uint256 amount)
        public
        payable
    {
        // read bond
        Bond memory b = _serviceBond(id, amount);
        Currency memory c = currencies[b.currencyRef];
        require(
            c.currencyType == 2,
            "LifecycleManager: wrong servicing currency"
        );
        // pay beneficiary
        if (c.ERC1155Id == 0) c.ERC1155Id = uint256(c.ERC1155SmallId);
        IERC1155(c.location).safeTransferFrom(
            msg.sender,
            b.beneficiary,
            c.ERC1155Id,
            amount,
            ""
        );
    }

    function serviceBondWithERC1155NFT(uint256 id, uint256 nftId)
        public
        payable
    {
        // read bond
        Bond memory b = _serviceBond(id, 1);
        Currency memory c = currencies[b.currencyRef];
        require(
            c.currencyType == 3,
            "LifecycleManager: wrong servicing currency"
        );
        // pay beneficiary
        IERC1155(c.location).safeTransferFrom(
            msg.sender,
            b.beneficiary,
            nftId,
            1,
            ""
        );
    }
}
