// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract ERC721ReceiverExposed is IERC721Receiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory data
    ) external pure override returns (bytes4 retval) {
        if (bytes1(data) != 0) {
            return 0;
        }
        return IERC721Receiver.onERC721Received.selector;
    }
}
