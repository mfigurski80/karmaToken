// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./MonetizedBondNFT.sol";

/**
 * @title 📃 Core Bond contract, containing all the methods and
 * data to create, read, update, delete bond financial primitives
 */
contract Core is MonetizedBondNFT {
  constructor(
    string memory name,
    string memory symbol,
    string memory uri
  ) MonetizedBondNFT(name, symbol, uri) // solhint-disable-next-line no-empty-blocks
  {}
}

