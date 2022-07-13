// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Exposed is ERC20 {
    constructor() ERC20("Gold", "GLD") {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}
