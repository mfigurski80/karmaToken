// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../CurrencyManager.sol";

contract CurrencyManagerExposed is CurrencyManager {
    function transferGenericCurrency(
        uint256 currencyId,
        address from,
        address to,
        uint256 amountOrId,
        bytes memory data
    ) external {
        _transferGenericCurrency(
            currencies[currencyId],
            from,
            to,
            amountOrId,
            data
        );
    }
}
