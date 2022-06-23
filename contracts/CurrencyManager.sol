// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/// @notice Enum representing various supported currency types
enum CurrencyType {
    Ether,
    ERC20,
    ERC721,
    ERC1155Token,
    ERC1155NFT
}

/// @notice Expanded Currency structure to be referenced by bonds
struct Currency {
    CurrencyType currencyType; // {ERC20, ERC721, ERC1155 tokens, ERC1155 NFTs} = {0,1,2,3}
    uint88 ERC1155SmallId;
    address location;
    uint256 ERC1155Id; // if ERC1155 and id > 500 septillion, use extra slot
}

/**
 * @title Contract that maintains an internal currency listings
 * @notice This listing is referred to in all future bonds and
 * collateral structures, used to figure out payment.
 */
contract CurrencyManager {
    // TODO: generic addCurrency?
    // TODO: check if address being added implements correct interface

    /**
     * @notice Array holding currency listing. Note that position 0
     * will always be taken by the Ethereum currency type, as
     * ensured by the constructor.
     */
    Currency[] public currencies;

    /// @notice new currency has been added to internal listing
    event CurrencyAdded(
        uint256 id,
        CurrencyType currencyType,
        address location,
        uint256 ERC1155Id
    );

    constructor() {
        currencies.push(Currency(CurrencyType.Ether, 0, address(0), 0));
    }

    /**
     * @notice Add a new currency of type ERC20
     * @param location address of the ERC20 contract being added
     */
    function addERC20Currency(address location) public payable virtual {
        _addCurrency(Currency(CurrencyType.ERC20, 0, location, 0));
    }

    /**
     * @dev Add a new currency of type ERC721
     * @param location address of the ERC721 contract being added
     */
    function addERC721Currency(address location) public payable virtual {
        _addCurrency(Currency(CurrencyType.ERC721, 0, location, 0));
    }

    /**
     * @notice Add a new currency of type ERC1155 Token
     * @param location address of the ERC1155 contract being added
     * @param tokenId specific tokenId to associate with this ERC1155
     * currency listing.
     * @dev TokenId is required because structures that reference
     * this currency are only able to specify one field -- the amount, and
     * so the tokenId must be constant and specified here
     */
    function addERC1155TokenCurrency(address location, uint256 tokenId)
        public
        payable
        virtual
    {
        Currency memory c = Currency(
            CurrencyType.ERC1155Token,
            uint88(tokenId),
            location,
            0
        );
        if (c.ERC1155SmallId != tokenId) {
            c.ERC1155Id = tokenId;
        }
        _addCurrency(c);
    }

    /**
     * @notice Add a new currency of type ERC1155 NFT.
     * @dev Note that no tokenId is required -- since we know the count to
     * be 1, the structures that reference this currency can use their
     * field to specify the tokenId.
     * @param location address of ERC1155 contract being added
     */
    function addERC1155NFTCurrency(address location) public payable virtual {
        _addCurrency(Currency(CurrencyType.ERC1155NFT, 0, location, 0));
    }

    /**
     * @dev transfers any supported currency using it's own interface
     * @param cur Currency type to transfer
     * @param from Which address to transfer from
     * @param to Which address to transfer to
     * @param amountOrId Either amount or id.
     * @param data bytes to pass on with the transaction
     * @dev The amountOrId paramenter represents the missing integer
     * that Currency doesn't store itself -- in the case of a fungible
     * token, the amount, but in the case of an NFT, the token id.
     */
    function _transferGenericCurrency(
        Currency storage cur,
        address from,
        address to,
        uint256 amountOrId,
        bytes memory data
    ) internal returns (bool) {
        if (cur.currencyType == CurrencyType.ERC20) {
            if (from == address(this)) {
                return IERC20(cur.location).transfer(to, amountOrId);
            } else {
                return IERC20(cur.location).transferFrom(from, to, amountOrId);
            }
        } else if (cur.currencyType == CurrencyType.ERC721) {
            IERC721(cur.location).safeTransferFrom(from, to, amountOrId, "");
        } else if (cur.currencyType == CurrencyType.ERC1155Token) {
            if (cur.ERC1155Id == 0) cur.ERC1155Id = uint256(cur.ERC1155SmallId);
            IERC1155(cur.location).safeTransferFrom(
                from,
                to,
                cur.ERC1155Id,
                amountOrId,
                data
            );
        } else if (cur.currencyType == CurrencyType.ERC1155NFT) {
            IERC1155(cur.location).safeTransferFrom(
                from,
                to,
                amountOrId,
                1,
                data
            );
        }
        return true;
    }

    /**
     * @dev Internal method to append a new currency efficiently.
     * @param c pre-build Currency structure to be added.
     */
    function _addCurrency(Currency memory c) internal {
        currencies.push(c);
        uint256 id = 0;
        if (c.currencyType == CurrencyType.ERC1155Token) {
            id = c.ERC1155SmallId;
            if (c.ERC1155Id != 0) id = c.ERC1155Id;
        }
        emit CurrencyAdded(
            currencies.length - 1,
            c.currencyType,
            c.location,
            id
        );
    }
}
