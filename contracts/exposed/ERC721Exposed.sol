// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../tokens/ERC721.sol";

// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract ERC721Exposed is ERC721 {
    constructor(
        string memory name_,
        string memory symbol_,
        string memory uri_
    ) ERC721(name_, symbol_, uri_) {}

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }
}
