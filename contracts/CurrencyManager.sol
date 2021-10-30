// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

struct Currency {
    uint8 currencyType; // {ERC20, ERC721, ERC1155} = {0,1,2}
    address location;
}

contract CurrencyManager {
    Currency[] public currencies;

    event CurrencyAdded(uint256 id, uint8 currencyType, address location);

    function addCurrency(uint8 currencyType, address location) public {
        require(currencyType < 3, "CurrencyManager: type value not supported");
        currencies.push(Currency(currencyType, location));
        emit CurrencyAdded(currencies.length - 1, currencyType, location);
    }
}
