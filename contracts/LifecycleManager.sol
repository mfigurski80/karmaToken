// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./BondToken.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/**
 * @dev 🦓 LifecycleManager contract exposing methods related to bringing
 * a bond through it's full lifecycle of servicing, repayment, and
 * default.
 */
contract LifecycleManager is BondToken {
    using LBondManager for bytes32;

    /// @notice new bond payment has been posted
    event BondServiced(uint256 id, address operator, uint64 toPeriod);
    /// @notice bond has been entirely repayed
    event BondCompleted(uint256 id);
    /// @notice bond payments have been failed
    event BondDefaulted(uint256 id);

    constructor(
        string memory name,
        string memory symbol,
        string memory uri
    )
        BondToken(name, symbol, uri) // solhint-disable-next-line no-empty-blocks
    {}

    // SERVICE PAYMENT METHODS

    /**
     * @dev Internal method contains logic for updating bond periods
     * @param id Id of bond to apply service payments to
     * @param value Amount of service payments to apply
     * @return Bond structure, but with only alpha elements filled
     */
    function _serviceBond(uint256 id, uint256 value)
        internal
        returns (Bond memory)
    {
        // read bond
        Bond memory b;
        bytes32 alpha = bonds[id * 2];
        b = alpha.fillBondFromAlpha(b);
        // figure out period change
        uint16 addedPeriods = uint16(value / b.couponSize);
        require(
            addedPeriods > 0,
            "LifecycleManager: service payment insufficient"
        );
        b.curPeriod += addedPeriods;
        if (b.curPeriod > b.nPeriods) {
            // might be complete... read beta to find face value
            if (
                (b.curPeriod - b.nPeriods) * b.couponSize >=
                bonds[id * 2 + 1].readFaceValue()
            ) {
                b.curPeriod = b.nPeriods + 1;
                emit BondCompleted(id);
            } else b.curPeriod = b.nPeriods;
        }
        bonds[id * 2] = alpha.writeCurPeriod(b.curPeriod);
        return b;
        // presumably, after return:
        // calling function should check for matching currency
        // and pay bond holder whatever he is due in that currency
    }

    /**
     * @dev services a referenced bond with ether sent along
     * with transaction.
     * @param id Id of bond to apply service payments to
     */
    function serviceBondWithEther(uint256 id) public payable {
        // read bond
        Bond memory b = _serviceBond(id, msg.value);
        require(
            b.currencyRef == 0,
            "LifecycleManager: wrong servicing currency"
        );
        // pay beneficiary
        (bool success, ) = b.beneficiary.call{value: msg.value}("");
        require(success, "LifecycleManager: ether transaction failed");
        emit BondServiced(id, msg.sender, b.curPeriod);
    }

    /**
     * @dev services a referenced bond with ERC20 tokens authorized
     * for withdrawal.
     * @param id Id of bond to apply service payments to
     * @param value Among of ERC20 to withdraw from caller's account
     * to apply as a service payment
     */
    function serviceBondWithERC20(uint256 id, uint256 value) public payable {
        // read bond
        Bond memory b = _serviceBond(id, value);
        Currency memory c = currencies[b.currencyRef];
        require(
            c.currencyType == CurrencyType.ERC20,
            "LifecycleManager: wrong servicing currency"
        );
        // pay beneficiary
        bool success = IERC20(c.location).transferFrom(
            msg.sender,
            b.beneficiary,
            value
        );
        require(success, "LifecycleManager: erc20 transaction failed");
        emit BondServiced(id, msg.sender, b.curPeriod);
    }

    /**
     * @dev services a referenced bond with ERC1155 tokens authorized
     * for withdrawal.
     * @param id Id of bond to apply service payments to
     * @param value Among of ERC1155 to withdraw from caller's account
     * to apply as a service payment
     */
    function serviceBondWithERC1155Token(uint256 id, uint256 value)
        public
        payable
    {
        // read bond
        Bond memory b = _serviceBond(id, value);
        Currency memory c = currencies[b.currencyRef];
        require(
            c.currencyType == CurrencyType.ERC1155Token,
            "LifecycleManager: wrong servicing currency"
        );
        // pay beneficiary
        if (c.ERC1155Id == 0) c.ERC1155Id = uint256(c.ERC1155SmallId);
        IERC1155(c.location).safeTransferFrom(
            msg.sender,
            b.beneficiary,
            c.ERC1155Id,
            value,
            ""
        );
        emit BondServiced(id, msg.sender, b.curPeriod);
    }

    // PAYMENT RECEIVER FUNCTIONS

    /**
     * TODO: write documentation
     */
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 value,
        bytes memory userData,
        bytes memory operatorData
    ) external {
        // for ERC777
        // TODO: do we even need this? Doesn't seem to be what I want...
        // TODO: contract might need to be registered in ERC1820 registry
    }

    /**
     * TODO: write documentation
     */
    function onERC1155Received(
        address operator,
        address,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4) {
        // for ERC1155
        // TODO: register interface
        if (operator == address(this)) return 0xf23a6e61; // erc1155 received

        uint256 bondId = uint256(bytes32(data)); // read bondId from data
        Bond memory b = _serviceBond(bondId, value);
        Currency memory c = currencies[b.currencyRef];
        require(
            c.currencyType == CurrencyType.ERC1155Token,
            "LifecycleManager: wrong servicing currency"
        );
        require(
            c.location == msg.sender,
            "LifecycleManager: wrong servicing currency contract"
        );
        // pay beneficiary
        if (c.ERC1155Id == 0) c.ERC1155Id = uint256(c.ERC1155SmallId);
        require(c.ERC1155Id == id, "LifecycleManager: wrong erc1155 id");
        IERC1155(c.location).safeTransferFrom(
            address(this),
            b.beneficiary,
            c.ERC1155Id,
            value,
            data
        );
        emit BondServiced(id, msg.sender, b.curPeriod);
        return 0xf23a6e61; // ERC1155 transfer accepted
    }

    // OTHER BOND MANAGEMENT

    /**
     * @dev call bond to mark it as in default. Can only be performed
     * by token owner or authorized operator.
     * @param id Id of bond to check for default
     */
    function callBond(uint256 id) public onlyValidOperator(id) {
        // check if bond is overdue
        bytes32 alpha = bonds[id * 2];
        Bond memory b = alpha.fillBondFromAlpha(
            Bond(false, 0, 0, 0, 0, 0, 0, 0, address(0), address(0))
        );
        require( // check if bond is done
            b.curPeriod < b.nPeriods + 1, // check for
            "LifecycleManager: bond completed"
        );
        require(
            b.curPeriod * b.periodDuration < block.timestamp - b.startTime,
            "LifecycleManager: bond not overdue"
        );
        // mark defaulted
        bonds[id * 2] = alpha.writeFlag(true);
        emit BondDefaulted(id);
    }

    /**
     * @dev set bond as complete and forfeight future payments. Can only
     * be performed by token owner or authorized operator.
     * @param id Id of bond to forgive
     */
    function forgiveBond(uint256 id) public onlyValidOperator(id) {
        bytes32 alpha = bonds[id * 2];
        (uint16 per, ) = alpha.readPeriodData();
        bonds[id * 2] = alpha.writeCurPeriod(per + 1);
        emit BondCompleted(id);
    }

    /**
     * TODO: write documentation
     * TODO: prevent abuse a la "owner destroys after getting all money,
     * preventing minter from retrieving their collateral"
     */
    function destroyBond(uint256 id) public onlyValidOperator(id) {
        delete bonds[id * 2];
        delete bonds[id * 2 + 1];
        address owner = _owners[id];
        delete _owners[id];
        delete _tokenApprovals[id];
        _balances[owner] -= 1;
    }
}
