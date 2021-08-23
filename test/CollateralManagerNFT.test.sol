// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/CollateralManager.sol";

import "@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";

// TEST WITH NFT

contract TestCollateralManagerNFT {
    CollateralManager manager;
    ERC721PresetMinterPauserAutoId nftContract = // FIXME: Ahhh revert if uncommented ahhh
        new ERC721PresetMinterPauserAutoId("TEST NFT", "NFT", "");
    uint256 ID = 0;

    function beforeEach() public {
        manager = new CollateralManager();
    }

    // TESTS

    function testInitialConditions() public {
        // TODO: test nft
        ERC721Collateral[] memory col = manager.listERC721(ID);
        Assert.equal(col.length, 0, "No collateral nfts exist initially");
    }

    function testReserveERC721() public {
        // init nft
        nftContract.mint(address(this));
        nftContract.approve(address(manager), 0);
        // reserve collateral
        ERC721Collateral memory tokenCollateral = ERC721Collateral(nftContract, 0);
        manager.reserveERC721(tokenCollateral, ID, address(this));
        // check reservation
        ERC721Collateral[] memory col = manager.listERC721(ID);
        Assert.equal(col.length, 1, "Collateral nft is added and recorded by manager");
        // check ownership
        address newOwner = nftContract.ownerOf(0);
        Assert.equal(newOwner, address(manager), "Collateral nft is owned by manager");
    }

    function testRelease() public {
        // init nft
        nftContract.mint(address(this));
        nftContract.approve(address(manager), 1);
        // reserve collateral
        ERC721Collateral memory tokenCollateral = ERC721Collateral(nftContract, 1);
        manager.reserveERC721(tokenCollateral, ID, address(this));
        // release
        manager.release(ID, address(this));
        // check reservation
        ERC721Collateral[] memory col = manager.listERC721(ID);
        Assert.equal(col.length, 0, "Collateral nft is no longer recorded by manager");
        // check ownership
        address newOwner = nftContract.ownerOf(1);
        Assert.equal(newOwner, address(this), "Collateral nft is owned by address given at release");
    }

}