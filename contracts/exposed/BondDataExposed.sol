// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../BondData.sol";

contract BondDataExposed is BondData {
    function writeBondAlpha(uint256 id, bytes32 alp) public {
        return _writeBondAlpha(id, alp);
    }

    function writeBondBeta(uint256 id, bytes32 bet) public {
        return _writeBondBeta(id, bet);
    }

    function addBond(bytes32 alp, bytes32 bet) public returns (uint256 id) {
        return _addBond(alp, bet);
    }
}
