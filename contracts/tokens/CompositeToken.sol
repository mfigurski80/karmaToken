// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

import "./ICompositeToken.sol";
import "./ERC721.sol";

import "../utils/Address.sol";

contract CompositeToken is ICompositeToken, ERC721 {
    using Address for address;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory uri_
    )
        ERC721(name_, symbol_, uri_) //solhint-disable-next-line no-empty-blocks
    {}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * Gets batch of owners from give id list
     */
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

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            account != address(0),
            "ERC1155: balance query for the zero address"
        );
        if (_owners[id] == account) return 1;
        return 0;
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(
            accounts.length == ids.length,
            "ERC1155: accounts and ids length mismatch"
        );

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            if (_owners[ids[i]] == accounts[i]) {
                batchBalances[i] = 1;
            }
            // batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external virtual override checkValidOperator(id) {
        require(amount == 1, "ERC1155: cannot transfer more than balance");
        _transfer(from, to, id);
        emit TransferSingle(msg.sender, from, to, id, amount);
        _checkOnERC1155Received(msg.sender, from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes memory data
    ) external virtual override {
        require(
            ids.length == amounts.length,
            "ERC1155: account and ids length mismatch"
        );
        for (uint256 i = 0; i < ids.length; i++) {
            // Check valid operator manually
            require(
                msg.sender == from || _operatorApprovals[from][msg.sender],
                "ERC1155: transfer caller is not owner or approved"
            );
            require(
                amounts[i] == 1,
                "ERC1155: cannot transfer more than balance"
            );
            _transfer(from, to, ids[i]);
        }
        emit TransferBatch(msg.sender, from, to, ids, amounts);
        _checkOnERC1155BatchReceived(msg.sender, from, to, ids, amounts, data);
    }

    function _checkOnERC1155Received(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155Received(
                    operator,
                    from,
                    id,
                    amount,
                    data
                )
            returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _checkOnERC1155BatchReceived(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155BatchReceived(
                    operator,
                    from,
                    ids,
                    amounts,
                    data
                )
            returns (bytes4 response) {
                if (
                    response != IERC1155Receiver.onERC1155BatchReceived.selector
                ) {
                    revert("ERC1155: ERC1155Receiver rejected batch tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiever implementer");
            }
        }
    }

    function _mint(address to, uint256 id) internal virtual override {
        super._mint(to, id);
        emit TransferSingle(msg.sender, address(0), to, id, 1);
    }

    function _mintBatch(address to, uint256[] memory ids) internal virtual {
        require(to != address(0), "ERC1155: mint to zero address");
        uint256[] memory amounts = new uint256[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            require(
                _owners[ids[i]] == address(0),
                "ERC1155: token already minted"
            );
            amounts[i] = 1;
            _owners[ids[i]] = to;
            emit Transfer(address(0), to, ids[i]);
        }
        _balances[to] += ids.length;
        emit TransferBatch(msg.sender, address(0), to, ids, amounts);
        _checkOnERC1155BatchReceived(
            msg.sender,
            address(0),
            to,
            ids,
            amounts,
            ""
        );
    }
}
