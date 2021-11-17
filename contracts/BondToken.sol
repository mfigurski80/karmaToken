// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./LBondManager.sol";
import "./CurrencyManager.sol";
import "./tokens/SuperERC721.sol";

contract BondToken is SuperERC721, CurrencyManager {
    bytes32[] public bonds;

    event BeneficiaryChange(uint256 id, address beneficiary);
    event BondServiced(uint256 id, address operator, uint64 toPeriod);

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

    // function serviceBond(uint256 bondId, uint256 value) public payable virtual {
    //     bytes32 alpha = bonds[bondId * 2];
    //     uint256 currencyRef = LBondManager.readCurrency(alpha);
    //     uint256 serviceValue = 0;
    //     if (currencyRef == 0) {
    //         // ether
    //         serviceValue = msg.value;
    //     } else {
    //         Currency memory c = currencies[currencyRef];
    //     }

    // accept any currency
    // ether or ERC20 or ERC1155 tokens
    // or even ERC721 or ERC1155 nfts?
    // step1: look up bond and figure out which currency it uses
    //  if currency ref is 0, service payment is msg.value
    //  if currency ref is ERC20 or ERC1155 token... grab `value` from it
    //      if not authorized operator, this'll fail. Yell at the user
    //  if currency ref is ERC721 or ERC1155 nft... grab that nft from it
    //      if not authorized operator, this'll fail too. Yell at user
    // step2: modify bond for curPeriod to reflect value given
    // step3: emit event
    // }
}
