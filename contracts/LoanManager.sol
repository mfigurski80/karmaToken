// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

struct PeriodicLoan {
    bool active; // whether contract is still active or completed
    address creditor; // 'owner' of contract
    address borrower; // 'minter' of contract
    uint256 period; // how often payments required
    uint256 nextServiceTime; // next payment required
    uint256 balance; // remaining payment amount
    uint256 minimumPayment; // minimum payment amount
    // Collateral[] collateral; // TODO: loan security
}

contract LoanManager {
    PeriodicLoan[] public loans;
    mapping(uint256 => uint256) public serviceReceived;

    event LoanCreated(
        uint256 id,
        address creator,
        uint256 amount,
        uint256 dueDate
    );
    event LoanServiced(uint256 id, address servicer, uint256 amount);
    event LoanCompleted(uint256 id, address servicer, bool isSuccessful);

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
        // TODO: figure out collateral transfers
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
     * @dev Allows user to service their loan with a set amount of ether. Allows
     *        for overserving, closes the loan if it's completed, and doesn't care
     *        about lateness of payment.
     * @param _id ID or index of loan you want to service
     * @param _with Amount of eth the loan has been serviced by
     */
    function _serviceLoan(uint256 _id, uint256 _with) internal {
        // get, check loan
        PeriodicLoan storage l = loans[_id];
        require(l.active, "LoanManager: Referenced token is not active");

        // figure out periods covered by payment
        uint256 fullPayment = _with + serviceReceived[_id];
        uint256 acceptedPayment = 0;
        uint256 periodsCovered = fullPayment / l.minimumPayment;
        // check if loan is fully paid
        if (l.balance <= fullPayment) {
            payable(l.creditor).transfer(l.balance);
            if (l.balance < fullPayment) {
                payable(l.borrower).transfer(fullPayment - l.balance);
            }
            _completeLoan(_id, true);
            return;
        }
        // else if not fully paid...
        if (periodsCovered > 0) {
            // find next service time
            l.nextServiceTime += periodsCovered * l.period;
            // update balance with period's payments
            acceptedPayment = l.minimumPayment * periodsCovered;
            payable(l.creditor).transfer(acceptedPayment);
            l.balance -= acceptedPayment;
            emit LoanServiced(_id, l.borrower, acceptedPayment);
        }
        // return overflow payment to storage
        serviceReceived[_id] = fullPayment - acceptedPayment;
    }

    /**
     * @dev Cancels the given loan id, performing the required checks
     * @param _id Id of loan you want to cancel
     */
    function _cancelLoan(uint256 _id) internal {
        // get, check loan
        PeriodicLoan storage l = loans[_id];
        require(l.active, "LoanManager: Referenced token is not active");

        _completeLoan(_id, true);
    }

    /**
     * @dev Checks to see if loan payments are overdue, and forfeits the
     *        security to the creditor if so
     * @param _id Id of loan you want to check
     */
    function _callLoan(uint256 _id) internal returns (bool) {
        PeriodicLoan storage l = loans[_id];
        require(l.active, "LoanManager: Referenced token is not active");

        if (block.timestamp > l.nextServiceTime) {
            // payment is overdue!
            _completeLoan(_id, false);
            return true;
        }
        return false;
    }

    function _completeLoan(uint256 _id, bool _successful) internal {
        PeriodicLoan storage l = loans[_id];
        l.active = false;
        // TODO: release collateral if _successful
        //       otherwise, release to creditor
        emit LoanCompleted(_id, l.borrower, _successful);
    }

    // solhint-disable-next-line
    receive() external payable {}
}