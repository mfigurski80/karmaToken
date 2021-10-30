// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./LBondManager.sol";
import "./tokens/SuperERC721.sol";

contract BondToken is SuperERC721 {
    bytes32[] public bonds;

    event BeneficiaryChange(uint256 id, address beneficiary);

    event BytesChange(uint256 i, bytes32 newBytes);

    constructor(
        string memory name,
        string memory symbol,
        string memory uri
    )
        SuperERC721(name, symbol, uri) // solhint-disable-next-line no-empty-blocks
    {}

    function getBond(uint256 id) public view returns (Bond memory) {
        return LBondManager.readBond(bonds[id * 2], bonds[id * 2 + 1]);
    }

    function mintBond(bytes32 alp, bytes32 bet) public {
        require(
            msg.sender == LBondManager.readMinter(bet),
            "BondToken: minter must be caller"
        );
        uint256 id = bonds.length / 2;
        bonds.push(alp);
        bonds.push(bet);
        _mint(msg.sender, id);
    }

    function updateBeneficiary(uint256 id, address newBeneficiary)
        public
        onlyValidOperator(id)
    {
        uint256 i = id * 2;
        bonds[i] = LBondManager.writeBeneficiary(bonds[i], newBeneficiary);
        emit BeneficiaryChange(id, newBeneficiary);
    }
}
