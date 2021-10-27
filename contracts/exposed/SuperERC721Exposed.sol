// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../tokens/SuperERC721.sol";

contract SuperERC721Exposed is SuperERC721 {
    constructor(
        string memory name_,
        string memory symbol_,
        string memory uri_
    )
        SuperERC721(name_, symbol_, uri_) // solhint-disable-next-line no-empty-blocks
    {}

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }

    function mintBatch(address to, uint256[] memory ids) public {
        _mintBatch(to, ids);
    }
}
