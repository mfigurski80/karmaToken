// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./LBondReader.sol";

contract BondData {
    bytes32[] public bonds;

    function test() public view returns (bytes32) {
        return bonds[0];
    }

    function getBond(uint256 id) public view returns (Bond memory) {
        return LBondReader.readBond(bonds[id * 2], bonds[id * 2 + 1]);
    }

    function getBondBytes(uint256 id) public view returns (bytes32, bytes32) {
        return (bonds[id * 2], bonds[id * 2 + 1]);
    }

    function _writeBondAlpha(uint256 id, bytes32 alp) internal {
        bonds[id * 2] = alp;
    }

    function _writeBondBeta(uint256 id, bytes32 bet) internal {
        bonds[id * 2 + 1] = bet;
    }

    function _addBond(bytes32 alp, bytes32 bet) internal returns (uint256 id) {
        id = bonds.length / 2;
        bonds.push(alp);
        bonds.push(bet);
    }
}
