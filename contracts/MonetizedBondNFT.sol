// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./CollateralManager.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MonetizedBondNFT is CollateralManager, Ownable {
    /**
     * @dev fee control for minting, specified in wei. Ranges from 18 eth (2**64) to
     * 0, where the next-smallest is 1 wei. Default .001 ether is ~ $1.15 (Jun 2022)
     */
    uint64 public mintFee = .001 ether;
    /**
     * @dev fee control for servicing, specified in parts to 1 billion. Ranges from
     * 18,446,744,073% to 0, where the next-smallest 0.0000001%. Default 1 million
     * is 0.1%.
     */
    uint64 public serviceFee = 1_000_000;

    event MintFeeChanged(uint64 newFee);
    event ServiceFeeChanged(uint64 newFee);

    constructor(
        string memory name,
        string memory symbol,
        string memory uri
    )
        CollateralManager(name, symbol, uri) // solhint-disable-next-line no-empty-blocks
    {}

    /**
     * @dev Sets initial mint fee (when minter is creating). Only
     *  callable by owner.
     * @param newFee New Fee to apply to all mints
     */
    function setMintFee(uint64 newFee) external onlyOwner {
        mintFee = newFee;
        emit MintFeeChanged(newFee);
    }

    /**
     * @dev Sets service fee (when minter is paying). Only
     * callable by owner.
     * @param newFee New Fee to bite out of service payments.
     */
    function setServiceFee(uint64 newFee) external onlyOwner {
        serviceFee = newFee;
        emit ServiceFeeChanged(newFee);
    }

    /**
     * @dev Retrieves fees to an alternative account, callable by owner.
     * Assumes that contract holds only ether related to fees -- no bond
     * or collateral has any references to ethereum stored in this
     * contract. TODO: this assumption is FALSE due to collateral storage
     * @param n Count of wei to transfer. Must be below total paid
     * @param to Address to transfer ether to
     * @param data Additional calldata to attach
     */
    function withdrawValue(
        uint256 n,
        address to,
        bytes memory data
    ) external onlyOwner {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = to.call{value: n}(data);
        require(success, "MonetizedBondNFT: withdraw failed");
    }

    // OVERRIDES

    /**
     * @dev Ensure user pays minting fee when minting
     */
    function mintBond(bytes32 alpha, bytes32 beta) public payable override {
        require(
            msg.value >= mintFee,
            "MonetizedLoanNFT: eth sent does not cover mint fee"
        );
        super.mintBond(alpha, beta);
    }

    // /**
    //  * @dev Ensure user pays service fee when servicing, but be aware value
    //  *  might be different based on what they're doing
    //  */
    // function serviceLoan(uint256 id) public payable override {
    //     uint256 fee = (msg.value * serviceFee) / 1_000_000_000;
    //     if ((msg.value * serviceFee) % 1_000_000_000 > 0) fee++; // round up fee
    //     uint256 trueValue = msg.value - fee;
    //     require(
    //         trueValue >= bonds[id].couponSize,
    //         "MonetizedLoanNFT: ether sent cannot cover service fee and minimum payment"
    //     );
    //     super.serviceLoan(id);
    // }
}
