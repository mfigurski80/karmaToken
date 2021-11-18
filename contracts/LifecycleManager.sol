// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./BondToken.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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

    function serviceBondWithEther(uint256 id) public payable {
        // read bond
        bytes32 alpha = bonds[id * 2];
        Bond memory b = LBondManager.fillBondFromAlpha(
            alpha,
            Bond(false, 0, 0, 0, 0, 0, 0, 0, address(0), address(0))
        );
        require(
            b.currencyRef == 0,
            "LifecycleManager: wrong servicing currency"
        );
        // figure out period change
        uint16 addedPeriods = uint16(msg.value / b.couponSize);
        require(
            addedPeriods > 0,
            "LifecycleManager: service payment insufficient"
        );
        b.curPeriod += addedPeriods;
        if (b.curPeriod > b.nPeriods) b.curPeriod = b.nPeriods;
        bonds[id * 2] = LBondManager.writeCurPeriod(alpha, b.curPeriod);
        // pay beneficiary
        (bool success, ) = b.beneficiary.call{value: msg.value}("");
        require(success, "LifecycleManager: transaction failed");
        emit BondServiced(id, b.curPeriod);
    }

    function serviceBondWithERC20(uint256 id, uint256 amount) public payable {
        // read bond
        bytes32 alpha = bonds[id * 2];
        Bond memory b = LBondManager.fillBondFromAlpha(
            alpha,
            Bond(false, 0, 0, 0, 0, 0, 0, 0, address(0), address(0))
        );
        Currency memory c = currencies[b.currencyRef];
        require(
            c.currencyType == 0,
            "LifecycleManager: wrong servicing currency"
        );
        // figure out period change
        uint16 addedPeriods = uint16(amount / b.couponSize);
        require(
            addedPeriods > 0,
            "LifecycleManager: service payment insufficient"
        );
        b.curPeriod += addedPeriods;
        if (b.curPeriod > b.nPeriods) b.curPeriod = b.nPeriods;
        bonds[id * 2] = LBondManager.writeCurPeriod(alpha, b.curPeriod);
        // pay beneficiary
        bool success = IERC20(c.location).transferFrom(
            msg.sender,
            b.beneficiary,
            amount
        );
        require(success, "LifecycleManager: transaction failed");
        emit BondServiced(id, b.curPeriod);
    }
}
