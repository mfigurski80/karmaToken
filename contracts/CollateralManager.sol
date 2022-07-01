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
        // TODO: Check for minter, owner agreement
        b = bonds[bondId * 2 + 1].fillBondFromBeta(b);
        bool isMinter = _minterOrOperatorOf(b.minter, operator);
        // if (isOwner && isMinter)
        // return true;
        // Check for completed + bond minter
        return (b.curPeriod > b.nPeriods && isMinter);
    }

    /**
     * @notice Release collateral by specified bond and collateral ids.
     * @dev Method is optimized to memoize the 'previous' bond and
     * currency used. If possible, sort incoming lists by bondIds and
     * by related currencyIds.
     * @param bondIds Integer array of bondIds to release collateral for
     * @param collateralIds Integer array of collateral ids related to
     * the bonds specified
     * @param to address to direct all collaterals to
     */
    function safeBatchReleaseCollaterals(
        uint256[] memory bondIds,
        uint256[] memory collateralIds,
        address to,
        bytes calldata data
    ) public {
        uint256 lastAuthorizedBond = 2**256 - 1;
        uint256 lastCurrencyRef = 2**256 - 1;
        Currency storage currency = currencies[0]; // TODO: figure out storage pointer
        for (uint256 i = 0; i < bondIds.length; i++) {
            uint256 bondId = bondIds[i];
            if (lastAuthorizedBond != bondId || lastAuthorizedBond == 2**256-1) {
                // if new bond, authorize release
                require(
                    _isAuthorizedToReleaseCollateral(bondId, msg.sender),
                    "CollateralManager: unauthorized to release collateral"
                );
                lastAuthorizedBond = bondId;
            }
            uint256 collateralId = collateralIds[i];
            Collateral memory c = collateral[bondId][collateralId];
            require(
                c.amountOrId > 0,
                "CollateralManager: this collateral has already been released"
            );
            if (lastCurrencyRef != c.currencyRef || lastCurrencyRef == 2**256-1) {
                // if new currency type, re-load currency
                currency = currencies[c.currencyRef];
                lastCurrencyRef = c.currencyRef;
            }
            delete collateral[bondId][collateralId];
            // TODO: release entire array if empty?
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
