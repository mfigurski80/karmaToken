// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./LoanManager.sol";

contract LoanToken is LoanManager, IERC721 {
    // STATE

    mapping(uint256 => address) tokenToOwner;
    mapping(address => uint256) ownerTokenCount;

    mapping(uint256 => address) tokenToApproval;
    mapping(address => address) ownerToApproval;

    // MODIFIERS

    modifier tokenExists(uint256 _tokenId) {
        require(loans.length > _tokenId);
        _;
    }
    modifier onlyOwner(uint256 _tokenId) {
        require(tokenToOwner[_tokenId] == msg.sender);
        _;
    }
    modifier onlyManager(uint256 _tokenId) {
        require(
            tokenToOwner[_tokenId] == msg.sender ||
                tokenToApproval[_tokenId] == msg.sender ||
                ownerToApproval[tokenToOwner[_tokenId]] == msg.sender,
            "Sender is not an authorized manager of this token"
        );
        _;
    }

    // INTERFACE METHODS

    function balanceOf(address owner)
        external
        view
        override
        returns (uint256 balance)
    {
        return ownerTokenCount[owner];
    }

    function ownerOf(uint256 tokenId)
        external
        view
        override
        tokenExists(tokenId)
        returns (address owner)
    {
        return tokenToOwner[tokenId];
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external override tokenExists(tokenId) onlyManager(tokenId) {
        // TODO: implement
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external override tokenExists(tokenId) onlyManager(tokenId) {
        require(
            tokenToOwner[tokenId] == from,
            "Transfer from user does not own this token"
        );
        ownerTokenCount[from]--;
        tokenToOwner[tokenId] = to;
        ownerTokenCount[to]++;
        tokenToApproval[tokenId] = address(0);
        emit Transfer(from, to, tokenId);
    }

    function approve(address to, uint256 tokenId)
        external
        override
        tokenExists(tokenId)
        onlyOwner(tokenId)
    {
        tokenToApproval[tokenId] = to;
        emit Approval(msg.sender, to, tokenId);
    }

    function getApproved(uint256 tokenId)
        external
        view
        override
        tokenExists(tokenId)
        returns (address operator)
    {
        return tokenToApproval[tokenId];
    }

    function setApprovalForAll(address operator, bool _approved)
        external
        override
    {
        if (!_approved) operator = address(0);
        ownerToApproval[msg.sender] = operator;
        emit ApprovalForAll(msg.sender, operator, _approved);
    }

    function isApprovedForAll(address owner, address operator)
        external
        view
        override
        returns (bool)
    {
        return ownerToApproval[owner] == operator;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external override onlyManager(tokenId) {
        // TODO: implement
    }

    function supportsInterface(bytes4 interfaceId)
        external
        view
        override
        returns (bool)
    {
        return false;
    }
}
