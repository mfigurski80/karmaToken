// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC721.sol";

contract SuperERC721 is ERC721 {
    constructor(
        string memory name_,
        string memory symbol_,
        string memory uri_
    )
        ERC721(name_, symbol_, uri_) // solhint-disable-next-line no-empty-blocks
    {}

    function balanceOfBatch(address[] memory owners)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory balances = new uint256[](owners.length);
        for (uint256 i = 0; i < owners.length; i++) {
            balances[i] = _balances[owners[i]];
        }
        return balances;
    }

    function ownerOfBatch(uint256[] memory ids)
        public
        view
        returns (address[] memory)
    {
        address[] memory owners = new address[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            owners[i] = _owners[ids[i]];
        }
        return owners;
    }

    function setBatchApprovalForAll(address[] memory operators, bool approved)
        public
    {
        for (uint256 i = 0; i < operators.length; i++) {
            _operatorApprovals[msg.sender][operators[i]] = approved;
            emit ApprovalForAll(msg.sender, operators[i], approved);
        }
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        bytes memory _data
    ) public {
        for (uint256 i = 0; i < ids.length; i++) {
            // check valid operator
            require(
                msg.sender == from ||
                    _operatorApprovals[from][msg.sender] ||
                    msg.sender == _tokenApprovals[ids[i]],
                "SuperERC721: caller is not valid operator"
            );
            _transfer(from, to, ids[i]);
            _checkOnERC721Received(from, to, ids[i], _data);
        }
    }

    function _mintBatch(address to, uint256[] memory ids) internal virtual {
        for (uint256 i = 0; i < ids.length; i++) {
            require(
                _owners[ids[i]] == address(0),
                "SuperERC721: token already minted"
            );
            _owners[ids[i]] = to;
            emit Transfer(address(0), to, ids[i]);
            _checkOnERC721Received(address(0), to, ids[i], "");
        }
        _balances[to] += ids.length;
    }
}
