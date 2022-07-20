// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./CollateralManager.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title 💸 Monetization for adding new currencies
 */
contract MonetizedBondNFT is CollateralManager, Ownable {
  /**
   * @notice Fee for adding currencies, specified in wei. Default
   * .01 ether is about ~ 13 USD
   */
  uint128 public currencyFee = .01 ether;

  // @notice Currency Fee has been updated
  event CurrencyFeeChanged(uint128 newFee);

  constructor(
    string memory name,
    string memory symbol,
    string memory uri
  )
  Ownable()
  CollateralManager(name, symbol, uri) // solhint-disable-next-line no-empty-blocks
  {}

  /**
   * @notice Set fee for adding a currency
   */
  function setCurrencyFee(uint128 newFee) public onlyOwner {
    currencyFee = newFee;
    emit CurrencyFeeChanged(newFee);
  }

  /**
   * @dev Take fee from transaction
   * @param fee Amount to take
   */
  function _takeFee(uint128 fee) internal {
    if (fee == 0) return;
    require(msg.value >= fee, "MonetizedBond: value sent cannot cover fee");
    (bool success, ) = owner().call{value: msg.value}("");
    require(success, "MonetizedBond: fee transaction failed");
  }

  /// OVERRIDES

  /**
   * @inheritdoc CurrencyManager
   */
  function addERC20Currency(address location) public payable override {
    _takeFee(currencyFee);
    super.addERC20Currency(location);
  }

  /**
   * @inheritdoc CurrencyManager
   */
  function addERC721Currency(address location) public payable override {
    _takeFee(currencyFee);
    super.addERC721Currency(location);
  }

  /**
   * @inheritdoc CurrencyManager
   */
  function addERC1155TokenCurrency(address location, uint256 tokenId)
    public
    payable
    override 
  {
    _takeFee(currencyFee);
    super.addERC1155TokenCurrency(location, tokenId);
  }

  /**
   * @inheritdoc CurrencyManager
   */
  function addERC1155NFTCurrency(address location) public payable override {
    _takeFee(currencyFee);
    super.addERC1155NFTCurrency(location);
  }

}

