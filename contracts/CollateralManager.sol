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

    event CollateralAdded(uint256 id, CurrencyType collateralType);
    event CollateralReleased(uint256 bondId, uint256 collateralId, address to);

    constructor(
        string memory name,
        string memory symbol,
        string memory uri
    )
        LifecycleManager(name, symbol, uri) // solhint-disable-next-line no-empty-blocks
    {}

    function addEtherCollateral(uint256 id) public payable {
        collateral[id].push(Collateral(msg.value, 0));
    }

    function addERC20Collateral(
        uint256 id,
        uint256 currencyRef,
        uint256 amount
    ) public payable {
        // find currency being referenced
        Currency storage c = currencies[currencyRef];
        require(c.currencyType == CurrencyType.ERC20);
        // pull collateral
        bool success = IERC20(c.location).transferFrom(
            msg.sender,
            address(this),
            amount
        );
        require(success, "CollateralManager: erc20 transfer failed");
        // add collateral entry
        collateral[id].push(Collateral(amount, currencyRef));
        emit CollateralAdded(id, CurrencyType.ERC20);
    }

    function addERC721Collateral(
        uint256 id,
        uint256 currencyRef,
        uint256 nftId
    ) public {
        Currency storage c = currencies[currencyRef];
        require(c.currencyType == CurrencyType.ERC721);
        IERC721(c.location).transferFrom(msg.sender, address(this), nftId);
        collateral[id].push(Collateral(nftId, currencyRef));
        emit CollateralAdded(id, CurrencyType.ERC721);
    }

    function addERC1155TokenCollateral(
        uint256 id,
        uint256 currencyRef,
        uint256 amount
    ) public {
        Currency storage c = currencies[currencyRef];
        require(c.currencyType == CurrencyType.ERC1155Token);
        if (c.ERC1155Id == 0) c.ERC1155Id = uint256(c.ERC1155SmallId);
        IERC1155(c.location).safeTransferFrom(
            msg.sender,
            address(this),
            c.ERC1155Id,
            amount,
            ""
        );
        collateral[id].push(Collateral(amount, currencyRef));
        emit CollateralAdded(id, CurrencyType.ERC1155Token);
    }

    function addERC1155NFTCollateral(
        uint256 id,
        uint256 currencyRef,
        uint256 nftId
    ) public {
        Currency storage c = currencies[currencyRef];
        require(c.currencyType == CurrencyType.ERC1155NFT);
        IERC1155(c.location).safeTransferFrom(
            msg.sender,
            address(this),
            nftId,
            1,
            ""
        );
        collateral[id].push(Collateral(nftId, currencyRef));
        emit CollateralAdded(id, CurrencyType.ERC1155NFT);
    }

    function _isAuthorizedToReleaseCollateral(uint256 bondId, address operator)
        internal
        view
        returns (bool)
    {
        Bond memory b;
        // Check for default + bond ownership
        b = bonds[bondId * 2].fillBondFromAlpha(b);
        if (b.flag && _ownerOrOperatorOf(bondId, _owners[bondId], operator)) {
            return true;
        }

        // Check for completed + bond minter
        b = bonds[bondId * 2 + 1].fillBondFromBeta(b);
        // return _minterOrOperatorOf(b.minter, operator);

        if (
            b.curPeriod > b.nPeriods && _minterOrOperatorOf(b.minter, operator)
        ) {
            return true;
        }
        return false;
    }

    function releaseCollaterals(
        uint256[] memory bondIds,
        uint256[] memory collateralIds,
        address to
    ) public {
        // TODO: de-duplicate reads of bonds, reads of currency
        // Potentially, this could be easier by assuming similar bonds are
        // positioned next to each other -- we can just check the previous
        // one to know if it's been already done
        // uint256[] memory bondIdsAuthorized = new uint256[](bondIds.length);
        // TODO: free storage after releasing
        for (uint256 i = 0; i < bondIds.length; i++) {
            uint256 bondId = bondIds[i];
            uint256 collateralId = collateralIds[i];
            require(
                _isAuthorizedToReleaseCollateral(bondId, msg.sender),
                "CollateralManager: unauthorized to release collateral"
            );
            Collateral storage c = collateral[bondId][collateralId];
            Currency storage cur = currencies[c.currencyRef];
            _transferGenericCurrency(cur, address(this), to, c.amountOrId, "");
            emit CollateralReleased(bondId, collateralId, to);
        }
    }
}
