// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./LifecycleManager.sol";
import "./CurrencyManager.sol";

struct Collateral {
    uint256 amountOrId;
    uint256 currencyRef;
}

contract CollateralManager is LifecycleManager {
    mapping(uint256 => Collateral[]) public collateral;

    event CollateralAdded(uint256 id, CurrencyType collateralType);

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
}
