// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0;

struct Collateral {
    CollateralType _type; // type of collateral
    address manager; // managing contract address
    uint256 nftId; // IF ERC721: which token
    uint256 balance; // IF ERC20: how many tokens
}

enum CollateralType {
    ERC20,
    ERC721
}
