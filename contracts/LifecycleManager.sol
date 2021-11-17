// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./BondToken.sol";

/**
 * 🦓 Lifecycle Manager
 */
contract LifecycleManager is BondToken {
    event BondServiced(uint256 id, uint64 toPeriod);

    constructor(
        string memory name,
        string memory symbol,
        string memory uri
    )
        BondToken(name, symbol, uri) // solhint-disable-next-line no-empty-blocks
    {}

    function serviceBond(uint256 id) public payable {
        // read bond
        bytes32 alpha = bonds[id * 2];
        Bond memory b = LBondManager.fillBondFromAlpha(
            alpha,
            Bond(false, 0, 0, 0, 0, 0, 0, 0, address(0), address(0))
        );
        // figure out value/currency sent
        uint256 serviceValue = 0;
        CurrencyType curType;
        if (b.currencyRef == 0) {
            // ether
            serviceValue = msg.value;
            curType = CurrencyType.Ether;
        } else {
            // TODO: implement not ether?
            // Currency memory c = currencies[currencyRef];
            revert("LifecycleManager: currency type not supported");
        }
        // figure out period change
        uint16 addedPeriods = uint16(serviceValue / b.couponSize);
        require(
            addedPeriods > 0,
            "LifecycleManager: service payment insufficient"
        );
        b.curPeriod += addedPeriods;
        if (b.curPeriod > b.nPeriods) b.curPeriod = b.nPeriods;
        // implement period change
        bonds[id * 2] = LBondManager.writeCurPeriod(alpha, b.curPeriod);
        // pay beneficiary
        bool success = false;
        if (curType == CurrencyType.Ether)
            (success, ) = b.beneficiary.call{value: serviceValue}("");
        require(success, "LifecyceManager: transfer failed");
        // emit event
        emit BondServiced(id, b.curPeriod);
    }
}
