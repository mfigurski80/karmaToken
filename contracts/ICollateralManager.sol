// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

enum ContractType {
    ERC20,
    ERC721
}

struct Collateral {
    ContractType contractType;
    address contractAddress;
    address owner;
    uint256 idOrCount;
}

struct ERC20Collateral {
    IERC20 contractAddress;
    uint256 count;
}

struct ERC721Collateral {
    IERC721 contractAddress;
    uint256 id;
}

interface ICollateralManager {
    function reserveERC20(
        ERC20Collateral memory,
        uint256,
        address
    ) external;

    function reserveERC721(
        ERC721Collateral memory,
        uint256,
        address
    ) external;

    function release(uint256, address) external;

    function listERC20(uint256)
        external
        view
        returns (ERC20Collateral[] memory);

    function listERC721(uint256)
        external
        view
        returns (ERC721Collateral[] memory);

    function listAll(uint256)
        external
        view
        returns (ERC20Collateral[] memory, ERC721Collateral[] memory);
}
