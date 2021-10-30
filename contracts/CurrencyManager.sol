// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

struct Currency {
    uint8 currencyType; // {ERC20, ERC721, ERC1155} = {0,1,2}
    address location;
    uint256 ERC1155Id; // if ERC1155, use extra slot
}

contract CurrencyManager {
    Currency[] public currencies;

    event CurrencyAdded(
        uint256 id,
        uint8 currencyType,
        address location,
        uint256 currencyId
    );

    constructor() {
        currencies.push(Currency(0, address(0), 0));
    }

    function addCurrency(
        uint8 currencyType,
        address location,
        uint256 currencyId
    ) public {
        require(currencyType < 3, "CurrencyManager: type value not supported");
        currencies.push(Currency(currencyType, location, currencyId));
        emit CurrencyAdded(
            currencies.length - 1,
            currencyType,
            location,
            currencyId
        );
    }
}
