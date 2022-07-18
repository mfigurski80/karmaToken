// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./CollateralManager.sol";

/**
 * @title 📃 Core Bond contract
 */
contract Core is CollateralManager {
  constructor(
    string memory name,
    string memory symbol,
    string memory uri
  ) CollateralManager(name, symbol, uri) // solhint-disable-next-line no-empty-blocks
  {}
}

