// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// @dev Enum representing various supported currency types
enum CurrencyType {
    Ether,
    ERC20,
    ERC721,
    ERC1155Token,
    ERC1155NFT
}

/// @dev expanded Currency structure, including all of it's fields
struct Currency {
    CurrencyType currencyType; // {ERC20, ERC721, ERC1155 tokens, ERC1155 NFTs} = {0,1,2,3}
    uint88 ERC1155SmallId;
    address location;
    uint256 ERC1155Id; // if ERC1155 and id > 500 septillion, use extra slot
}

/**
 * @dev CurrencyManager contract exposing methods to update internal
 * currency listing, which is then referred to in all future bonds
 * and collateral.
 */
contract CurrencyManager {
    /**
     * @dev Array holding currency listing. Note that position 0
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
     * @dev Add a new currency of type ERC20
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
     * @dev Add a new currency of type ERC1155 Token
     * @param location address of the ERC20 contract being added
     * @param tokenId specific tokenId to associate with this ERC1155
     * currency listing. This is present because structures that reference
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
     * @dev Add a new currency of type ERC1155 NFT. Note that no tokenId
     * is required -- since we know the count to be 1, the structures that
     * reference this currency can use their field to specify the tokenId.
     * @param location address of ERC1155 contract being added
     */
    function addERC1155NFTCurrency(address location) public payable virtual {
        _addCurrency(Currency(CurrencyType.ERC1155NFT, 0, location, 0));
    }

    /**
     * @dev Internal method to append a new contract efficiently.
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
