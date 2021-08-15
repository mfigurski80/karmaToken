// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ICollateralManager.sol";

contract CollateralManager is ICollateralManager {
    mapping(uint256 => ERC20Collateral[]) public tokenCollateral;
    mapping(uint256 => ERC721Collateral[]) public nftCollateral;

    function reserveERC20(
        ERC20Collateral memory token,
        uint256 id,
        address owner
    ) external override {
        token.contractAddress.transferFrom(owner, address(this), token.count);
        tokenCollateral[id].push(token);
    }

    function reserveERC721(
        ERC721Collateral memory nft,
        uint256 id,
        address owner
    ) external override {
        nft.contractAddress.transferFrom(owner, address(this), nft.id);
        nftCollateral[id].push(nft);
    }

    function release(uint256 id, address to) external override {
        for (uint256 i = 0; i < tokenCollateral[id].length; i++) {
            ERC20Collateral storage token = tokenCollateral[id][i];
            token.contractAddress.transfer(to, token.count);
        }
        delete tokenCollateral[id];
        for (uint256 i = 0; i < nftCollateral[id].length; i++) {
            ERC721Collateral storage nft = nftCollateral[id][i];
            nft.contractAddress.transferFrom(address(this), to, nft.id);
        }
        delete nftCollateral[id];
    }

    function listERC20(uint256 id)
        external
        view
        override
        returns (ERC20Collateral[] memory)
    {
        return tokenCollateral[id];
    }

    function listERC721(uint256 id)
        external
        view
        override
        returns (ERC721Collateral[] memory)
    {
        return nftCollateral[id];
    }

    function listAll(uint256 id)
        external
        view
        override
        returns (ERC20Collateral[] memory, ERC721Collateral[] memory)
    {
        return (tokenCollateral[id], nftCollateral[id]);
    }
}
