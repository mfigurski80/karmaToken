// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/CollateralManager.sol";

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

// TEST WITH TOKEN

contract TestCollateralManagerToken {
    CollateralManager manager;
    ERC20PresetMinterPauser tokenContract =
        new ERC20PresetMinterPauser("TEST TOKEN", "TKN");
    uint256 ID = 0;

    function beforeEach() public {
        manager = new CollateralManager();
        // init token
        tokenContract.mint(address(this), 100);
    }

    // TESTS

    function testInitialConditions() public {
        ERC20Collateral[] memory col = manager.listERC20(ID);
        Assert.equal(col.length, 0, "No collateral tokens exists initially");
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
}
