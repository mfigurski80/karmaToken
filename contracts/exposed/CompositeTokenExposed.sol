// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../tokens/CompositeToken.sol";

contract CompositeTokenExposed is CompositeToken {
    constructor(
        string memory name_,
        string memory symbol_,
        string memory uri_
    ) CompositeToken(name_, symbol_, uri_) {}

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }

    function mintBatch(address to, uint256[] memory ids) public {
        _mintBatch(to, ids);
    }
}
