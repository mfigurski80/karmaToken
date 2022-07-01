// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./BondToken.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/**
 * @dev 🦓 LifecycleManager contract exposing methods related to bringing
 * a bond through it's full lifecycle of servicing, repayment, and
 * potentially default.
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
     * @param b Bond structure with alpha elements filled
     * @param alpha bytes32 of first bond slot data
     * @param id Id of bond to apply service payments to
     * @param value Amount of service payments to apply
     */
    function _updateBondPeriod(
        Bond memory b,
        bytes32 alpha,
        uint256 id,
        uint256 value
    ) internal {
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
        // presumably, after return:
        // calling function should check for matching currency
        // and pay bond holder whatever he is due in that currency
    }

    /**
     * @notice Services a specific bond with generic currency
     * @param id uint256 index of bond to service
     * @param from address account to take value from
     * @param value amount to apply to the bond, or the NFT id
     * to transfer
     * @param data bytes to send with the transaction
     * 
     * @dev For ether transactions, from and value still have
     * to match or exceed the ether sent and the message sender
     * @dev Note that call data will not get forwarded in all
     * cases
     */
    function serviceBond(
        uint256 id,
        address from,
        uint256 value,
        bytes calldata data
    ) public payable {
        // read bond
        Bond memory b;
        bytes32 alpha = bonds[id*2]; // READ A
        b = alpha.fillBondFromAlpha(b);
        require(b.flag, false, "LifecycleManager: cannot service defaulted bond");
        if (b.currencyRef == 0) { // special case for ether
            assert(msg.value >= value); 
            assert(msg.sender == from);
            _updateBondPeriod(b, alpha, id, value);
            (bool success, ) = b.beneficiary.call{value: value}(data);
            require(success, "LifecycleManager: ether transaction failed");
        } else {
            Currency storage c = currencies[b.currencyRef];
            CurrencyType typ = c.currencyType;
            if (typ == CurrencyType.ERC721 || typ == CurrencyType.ERC1155NFT)
                _updateBondPeriod(b, alpha, id, 1);
            else
                _updateBondPeriod(b, alpha, id, value);
            _transferGenericCurrency(c, from, b.beneficiary, value, data);
        }
        emit BondServiced(id, from, b.curPeriod);
    }

    // PAYMENT RECEIVER FUNCTIONS
    // discontinued due to discussion, refer commit a3cc493

    function onERC1155Received(
        address operator,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external view returns (bytes4) {
        // for ERC1155 single transfers
        if (operator == address(this)) return 0xf23a6e61;
        return 0x0;
    }

    function onERC721Received(
        address operator,
        address,
        uint256,
        bytes calldata
    ) external view returns (bytes4) {
        if (operator == address(this)) return this.onERC721Received.selector;
        return 0x0;
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
            b.curPeriod <= b.nPeriods,
            "LifecycleManager: cannot call completed bond"
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
     * @notice set bond as complete and forfeight future payments. Can only
     * be performed by token owner or authorized operator.
     * @param id uint256 bond index
     */
    function forgiveBond(uint256 id) public onlyValidOperator(id) {
        bytes32 alpha = bonds[id * 2];
        (uint16 per, ) = alpha.readPeriodData();
        bonds[id * 2] = alpha.writeCurPeriod(per + 1);
        emit BondCompleted(id);
    }

    /**
     * @notice destroy bond and all related resource, refunding gas
     * @param id uin256 bond index
     * @dev Needs to be overriden to remove collateral as well
     */
    function destroyBond(uint256 id) public virtual onlyValidOperator(id) {
        // Note: raw version implies owner can destroy at any time
        // frees 4 slots, writes to one
        delete bonds[id * 2]; 
        delete bonds[id * 2 + 1];
        address owner = _owners[id];
        delete _owners[id];
        delete _tokenApprovals[id];
        _balances[owner] -= 1;
    }
}
