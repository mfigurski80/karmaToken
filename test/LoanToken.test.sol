// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma abicoder v2;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/LoanToken.sol";

contract TestLoanToken {
    uint256 public constant initialBalance = 10000 wei; // NOTE: increase as you see fit
    LoanToken public token;

    function beforeEach() public {
        token = new LoanToken();
    }

    function testERC165() public {
        Assert.isTrue(
            token.supportsInterface(0x01ffc9a7),
            "Supports ERC165 interface"
        );
        Assert.isTrue(
            token.supportsInterface(0x80ac58cd),
            "Supports ERC721 interface"
        );
        Assert.isFalse(
            token.supportsInterface(0xffffffff),
            "Does not support null interface"
        );
    }
}
