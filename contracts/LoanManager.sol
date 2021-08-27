// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./CollateralManager.sol";

struct PeriodicLoan {
    bool active; // whether contract is still active or completed
    address beneficiary; // address service payments should be made to
    address borrower; // 'minter' of contract
    uint256 period; // how often payments required
    uint256 nextServiceTime; // next payment required
    uint256 balance; // remaining payment amount
    uint256 minimumPayment; // minimum payment amount
}

contract LoanManager {
    PeriodicLoan[] public loans;
    CollateralManager collateralManager;

    event LoanCreated(
        uint256 id,
        address creator,
        uint256 amount,
        uint256 dueDate
    );
    event LoanServiced(uint256 id, address servicer, uint256 amount);
    event LoanCompleted(uint256 id, address servicer, bool isSuccessful);

    constructor(address managerAddress) {
        collateralManager = CollateralManager(managerAddress);
    }

    /**
     * @dev Allows updating the beneficiary of a specific loan
     * @param _id ID of loan to be updated
     * @param _newBeneficiary New address that will receive loan proceeds
     */
    function _updateBeneficiary(uint256 _id, address _newBeneficiary) internal {
        PeriodicLoan storage loan = loans[_id];
        loan.beneficiary = _newBeneficiary;
    }

    /**
     * @dev Allows easy creation of PeriodicLoan from given parameters
     * @param _maturity Date loan should mature
     * @param _period How often payments are required
     * @param _totalBalance Total eth transfered once loan matures
     * @return The Id of the newly-created PeriodicLoan, ie it's index in the list
     */
    function _createLoan(
        uint256 _maturity,
        uint256 _period,
        uint256 _totalBalance
    ) internal returns (uint256) {
        uint256 id = loans.length;
        // figure out minimum payment such that _totalBalance is payed
        uint256 duration = _maturity - block.timestamp;
        uint256 nPeriods = duration / _period;
        uint256 minPayment = _totalBalance / nPeriods;
        if (duration % nPeriods != 0) {
            minPayment++;
        }
        // add loan
        loans.push(
            PeriodicLoan(
                true,
                msg.sender,
                msg.sender,
                _period,
                block.timestamp + _period,
                _totalBalance,
                minPayment
            )
        );
        emit LoanCreated(id, msg.sender, _totalBalance, _maturity);
        return id;
    }

    /**
     * @dev allows you to add an ERC20 Collateral
     * @param _id ID of loan being referenced
     * @param _tokenAddress Location of ERC20 contract
     * @param _count Amount of ERC20 to be held as collateral
     */
    function _reserveERC20Collateral(
        uint256 _id,
        address _tokenAddress,
        uint256 _count
    ) internal {
        ERC20Collateral memory tok = ERC20Collateral(
            IERC20(_tokenAddress),
            _count
        );
        collateralManager.reserveERC20(tok, _id, msg.sender);
    }

    /**
     * @dev allows you to add ERC721 Collateral
     * @param _id ID of loan being referenced
     * @param _nftAddress Location of ERC721 contract
     * @param _nft ID of nft to hold as collateral
     */
    function _reserveERC721Collateral(
        uint256 _id,
        address _nftAddress,
        uint256 _nft
    ) internal {
        ERC721Collateral memory nft = ERC721Collateral(
            IERC721(_nftAddress),
            _nft
        );
        collateralManager.reserveERC721(nft, _id, msg.sender);
    }

    /**
     * @dev Allows user to service their loan with a set amount of ether. Allows
     *        for overserving, closes the loan if it's completed, and doesn't care
     *        about lateness of payment.
     * @param _id ID or index of loan you want to service
     * @param _with Amount of eth the loan has been serviced by
     */
    function _serviceLoan(uint256 _id, uint256 _with) internal {
        // get, check loan
        PeriodicLoan storage loan = loans[_id];
        require(loan.active, "LoanManager: Referenced token is not active");

        // check if loan is fully paid
        if (loan.balance <= _with) {
            _completeLoan(_id, true);
            payable(loan.beneficiary).transfer(loan.balance);
            if (loan.balance < _with) {
                payable(loan.borrower).transfer(_with - loan.balance);
            }
            return;
        }
        // else if not fully paid...
        require(
            _with >= loan.minimumPayment,
            "LoanManager: Payment doesn't meet minimum level for this contract"
        );
        // figure out periods covered by payment
        uint256 periodsCovered = _with / loan.minimumPayment;
        // find next service time && update balance
        loan.nextServiceTime += periodsCovered * loan.period;
        uint256 acceptedPayment = loan.minimumPayment * periodsCovered;
        loan.balance -= acceptedPayment;
        payable(loan.beneficiary).transfer(acceptedPayment); // watch for re-entrancy
        emit LoanServiced(_id, loan.borrower, acceptedPayment);
    }

    /**
     * @dev Cancels the given loan id, performing the required checks
     * @param _id Id of loan you want to cancel
     */
    function _cancelLoan(uint256 _id) internal {
        // get, check loan
        PeriodicLoan storage loan = loans[_id];
        require(loan.active, "LoanManager: Referenced token is not active");

        _completeLoan(_id, true);
    }

    /**
     * @dev Checks to see if loan payments are overdue, and forfeits the
     *        security to the creditor if so
     * @param _id Id of loan you want to check
     */
    function _callLoan(uint256 _id) internal returns (bool) {
        PeriodicLoan storage loan = loans[_id];
        require(loan.active, "LoanManager: Referenced token is not active");

        if (block.timestamp > loan.nextServiceTime) {
            // payment is overdue!
            _completeLoan(_id, false);
            return true;
        }
        return false;
    }

    function _completeLoan(uint256 _id, bool _successful) internal {
        PeriodicLoan storage loan = loans[_id];
        loan.active = false;
        if (_successful) {
            collateralManager.release(_id, loan.borrower);
        } else {
            collateralManager.release(_id, loan.beneficiary);
        }
        emit LoanCompleted(_id, loan.borrower, _successful);
    }

    // solhint-disable-next-line
    receive() external payable {}
}
