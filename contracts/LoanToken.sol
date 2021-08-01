// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./LoanManager.sol";

contract LoanToken is LoanManager, IERC721 {
    function balanceOf(address owner)
        external
        view
        override
        returns (uint256 balance)
    {
        return 0;
    }

    function ownerOf(uint256 tokenId)
        external
        view
        override
        returns (address owner)
    {
        return address(0x00);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external override {}

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external override {}

    function approve(address to, uint256 tokenId) external override {}

    function getApproved(uint256 tokenId)
        external
        view
        override
        returns (address operator)
    {
        return address(0x00);
    }

    function setApprovalForAll(address operator, bool _approved)
        external
        override
    {}

    function isApprovedForAll(address owner, address operator)
        external
        view
        override
        returns (bool)
    {
        return false;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external override {}
}
