// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

struct Currency {
    uint8 currencyType; // {ERC20, ERC721, ERC1155 tokens, ERC1155 NFTs} = {0,1,2,3}
    uint88 ERC1155SmallId;
    address location;
    uint256 ERC1155Id; // if ERC1155 and id > 500 septillion, use extra slot
}

contract CurrencyManager {
    Currency[] public currencies;

    event CurrencyAdded(
        uint256 id,
        uint8 currencyType,
        address location,
        uint256 ERC1155Id
    );

    constructor() {
        currencies.push(Currency(0, 0, address(0), 0));
    }

    function addERC20Currency(address location) public payable virtual {
        _addCurrency(Currency(0, 0, location, 0));
    }

    function addERC721Currency(address location) public payable virtual {
        _addCurrency(Currency(1, 0, location, 0));
    }

    function addERC1155TokenCurrency(address location, uint256 tokenId)
        public
        payable
        virtual
    {
        Currency memory c = Currency(2, uint88(tokenId), location, 0);
        if (c.ERC1155SmallId != tokenId) {
            c.ERC1155Id = tokenId;
        }
        _addCurrency(c);
    }

    function addERC1155Currency(address location) public payable virtual {
        _addCurrency(Currency(3, 0, location, 0));
    }

    function _addCurrency(Currency memory c) internal {
        currencies.push(c);
        uint256 id = 0;
        if (c.currencyType == 2) {
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
