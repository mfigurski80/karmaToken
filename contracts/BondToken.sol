// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./LBondManager.sol";
import "./CurrencyManager.sol";
import "./tokens/SuperERC721.sol";

/**
 * @dev BondToken contract holds a basic interface on top of ERC721
 * to manage the creation and reading of bonds. It's dependent on
 * the LBondManager library to interpret the condensed 64 byte
 * representation.
 */
contract BondToken is SuperERC721, CurrencyManager {
    using LBondManager for bytes32;

    /**
     * @dev bond data array, as interpreted by LBondManager library
     * contract. Each bond takes two slots, so bond of id i starts at
     * position 2i.
     */
    bytes32[] public bonds;

    /// @notice recipient of bond payments has been updated
    event BeneficiaryChange(uint256 id, address beneficiary);

    constructor(
        string memory name,
        string memory symbol,
        string memory uri
    )
        SuperERC721(name, symbol, uri) // solhint-disable-next-line no-empty-blocks
    {}

    /**
     * @dev interprets bond at given id into readable version
     * @param id is the target bond id
     * @return Bond as the expanded bond datastructure at given id
     */
    function getBond(uint256 id) public view returns (Bond memory) {
        return LBondManager.readBond(bonds[id * 2], bonds[id * 2 + 1]);
    }

    /**
     * @dev appends a new bond to the list
     * @param alp Alpha bytes to append, as interpreted by library
     * @param bet Beta bytes to append, as interpreted by library
     */
    function mintBond(bytes32 alp, bytes32 bet) public payable virtual {
        require(
            msg.sender == LBondManager.readMinter(bet),
            "BondToken: minter must be caller"
        );
        uint256 id = bonds.length / 2;
        bonds.push(alp);
        bonds.push(bet);
        _mint(msg.sender, id);
    }

    /**
     * @dev updates the beneficiary associated with a bond
     * @param id Bond id
     * @param newBeneficiary address of new beneficiary
     */
    function updateBeneficiary(uint256 id, address newBeneficiary)
        public
        onlyValidOperator(id)
    {
        uint256 i = id * 2;
        bonds[i] = LBondManager.writeBeneficiary(bonds[i], newBeneficiary);
        emit BeneficiaryChange(id, newBeneficiary);
    }
}
