// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma abicoder v2;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/LoanToken.sol";

import "./Utility.sol";

contract TestLoanToken is Utility {
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

    function testHasSymbolAndName() public {
        Assert.notEqual(token.symbol(), "", "Symbol is not empty");
        Assert.notEqual(token.name(), "", "Name is not empty");
    }

    function testMintLoan() public {
        uint256 id = token.mintLoan(block.timestamp + 7 days, 1 days, 100);
        // Assert.isTrue(token.loans(id), "Exists once minted");
        Assert.equal(token.ownerOf(id), address(this), "Owned by token minter");
        Assert.equal(
            token.balanceOf(address(this)),
            1,
            "Balance increases when minting token"
        );

        PeriodicLoan memory l = _getPeriodicLoan(id, token);
        Assert.isTrue(l.active, "Minted loan should be active initially");
        Assert.equal(
            l.balance,
            100,
            "Balance should be same as mint paramenter"
        );
    }
}
