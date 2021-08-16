// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/CollateralManager.sol";

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";

contract TestCollateralManager {
    CollateralManager manager;
    ERC20PresetMinterPauser tokenContract =
        new ERC20PresetMinterPauser("TEST TOKEN", "TKN");
    // ERC721PresetMinterPauserAutoId nftContract = // FIXME: Ahhh revert if uncommented ahhh
    //     new ERC721PresetMinterPauserAutoId("TEST NFT", "NFT", "");
    uint256 ID = 0;

    function beforeEach() public {
        manager = new CollateralManager();
        // init token
        tokenContract.mint(address(this), 100);
        // init nft
        // nftContract.mint(address(this));
    }

    // TESTS

    function testInitialConditions() public {
        ERC20Collateral[] memory col = manager.listERC20(ID);
        Assert.equal(col.length, 0, "No collateral tokens exists initially");
        // TODO: test nft
    }

    function testReserveERC20() public {
        tokenContract.increaseAllowance(address(manager), 10);
        // reserve collateral
        ERC20Collateral memory tokenCollateral = ERC20Collateral(
            tokenContract,
            10
        );
        manager.reserveERC20(tokenCollateral, ID, address(this));
        // check reservation
        ERC20Collateral[] memory col = manager.listERC20(ID);
        Assert.equal(col.length, 1, "Collateral token is added and stored");
    }

    // function testReserveERC721() public {
    //     nftContract.approve(address(manager), 0);
    //     // reserve collateral
    //     ERC721Collateral memory tokenCollateral = ERC721Collateral(
    //         nftContract,
    //         0
    //     );
    //     manager.reserveERC721(tokenCollateral, ID, address(this));
    //     // check reservation
    //     ERC721Collateral[] memory col = manager.listERC721(ID);
    //     Assert.equal(col.length, 1, "Collateral nft is added and stored");
    // }
}
