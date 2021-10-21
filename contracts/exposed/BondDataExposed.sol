// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../BondData.sol";

contract BondDataExposed is BondData {
    function writeBondAlpha(uint256 id, bytes32 alp) public {
        bonds[id * 2] = alp;
    }

    function writeBondBeta(uint256 id, bytes32 bet) public {
        bonds[id * 2 + 1] = bet;
    }

    function addBond(bytes32 alp, bytes32 bet) public returns (uint256 id) {
        id = bonds.length / 2;
        bonds.push(alp);
        bonds.push(bet);
    }
}
