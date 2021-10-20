// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract UpgradeableDelegate is Ownable {
    address public ref = address(0);
    bytes32 public refChange = 0;

    function submitChange(address newRef) public onlyOwner {
        // first 8 bytes are timestamp, 4 empty, last 20 are new ref
        bytes8 t = bytes8(uint64(block.timestamp));
        refChange = (bytes32(bytes20(newRef)) >> 96) | t;
    }

    function implementChange() public {
        // read timestamp and new ref
        uint64 t = uint64(bytes8(refChange));
        require(
            block.timestamp > t + 60 * 60 * 24 * 30,
            "LibraryInterface: Insufficient time since change proposal"
        );
        ref = address(bytes20(refChange << 96));
    }

    fallback() external payable {
        // do things
    }

    receive() external payable {
        // do same things?
    }
}
