// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./LifecycleManager.sol";
import "./CurrencyManager.sol";
import "./LBondManager.sol";

struct Collateral {
    uint256 amountOrId;
    uint256 currencyRef;
}

contract CollateralManager is LifecycleManager {
    using LBondManager for bytes32;

    mapping(uint256 => Collateral[]) public collateral;

    event CollateralAdded(
        uint256 bondId,
        uint256 collateralId,
        CurrencyType collateralType
    );
    event CollateralReleased(uint256 bondId, uint256 collateralId, address to);

    constructor(
        string memory name,
        string memory symbol,
        string memory uri
    )
        LifecycleManager(name, symbol, uri) // solhint-disable-next-line no-empty-blocks
    {}

    function addCollateral(
        uint256 id,
        uint256 currencyRef,
        uint256 valueOrId
    ) external payable {
        collateral[id].push(Collateral(valueOrId, currencyRef));
        CurrencyType typ = CurrencyType.Ether;
        if (currencyRef == 0) { // ether special case
            assert(msg.value == valueOrId);
        } else {
            Currency storage c = currencies[currencyRef];
            typ = c.currencyType;
            _transferGenericCurrency(c, msg.sender, address(this), valueOrId, "");
        }
        emit CollateralAdded(id, collateral[id].length - 1, typ);
    }

    function _isAuthorizedToReleaseCollateral(uint256 bondId, address operator)
        internal
        view
        returns (bool)
    {
        Bond memory b;
        // Check for default + bond ownership
        b = bonds[bondId * 2].fillBondFromAlpha(b);
        bool isOwner = _ownerOrOperatorOf(bondId, _owners[bondId], operator);
        if (b.flag && isOwner) return true;
        // Check for completed + bond minter
        b = bonds[bondId * 2 + 1].fillBondFromBeta(b);
        bool isMinter = _minterOrOperatorOf(b.minter, operator);
        return (b.curPeriod > b.nPeriods && isMinter);
    }

    /**
     * @notice Release last collateral attached to specified bonds ids
     * @dev Method is optimized to memoize the 'previous' bond and
     * currency used. If possible, sort incoming lists by bondIds and
     * by related currencyIds.
     * @param bondIds Integer array of bondIds to release collateral for
     * @param to address to direct all collaterals to
     * @param data bytes to forward with each transfer
     */
    function safeBatchReleaseCollaterals(
        uint256[] memory bondIds,
        address to,
        bytes calldata data
    ) public {
        uint256 lastAuthorizedBond = 2**256 - 1;
        uint256 lastCurrencyRef = 2**256 - 1;
        Currency storage currency = currencies[0]; // TODO: figure out storage pointer
        for (uint256 i = 0; i < bondIds.length; i++) {
            uint256 bondId = bondIds[i];
            // Check if this is an un-cached bond?
            if (lastAuthorizedBond != bondId || lastAuthorizedBond == 2**256-1) {
                // It is! Authorize new release
                require(
                    _isAuthorizedToReleaseCollateral(bondId, msg.sender),
                    "CollateralManager: unauthorized to release collateral"
                );
                lastAuthorizedBond = bondId;
            }
            // Get bond collateral (last in array), remove from storage 
            uint256 collateralId = collateral[bondId].length - 1; 
            Collateral memory c = collateral[bondId][collateralId];
            collateral[bondId].pop();
            require(
                c.amountOrId > 0,
                "CollateralManager: this collateral has already been released"
            );
            // Check if Collateral refers to a un-cached currency
            if (lastCurrencyRef != c.currencyRef || lastCurrencyRef == 2**256-1) {
                // It does! Re-load cached currency
                currency = currencies[c.currencyRef];
                lastCurrencyRef = c.currencyRef;
            }
            // Transfer collateral
            _transferGenericCurrency(
                currency,
                address(this),
                to,
                c.amountOrId,
                data 
            );
            emit CollateralReleased(bondId, collateralId, to);
        }
    }

    /**
     * @inheritdoc LifecycleManager
     * @notice Collateral must be entirely released to allow bond destruction
     */
    function destroyBond(uint256 id) public override onlyValidOperator(id) {
        assert(collateral[id].length == 0);
        delete collateral[id];
        super.destroyBond(id);
    } 
}
