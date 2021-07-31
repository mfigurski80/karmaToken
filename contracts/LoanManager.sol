// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0;

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
    event LoanCompleted(uint256 id, address servicer);

    /// @notice Allows easy creation of PeriodicLoan from given parameters
    /// @param _dueDate Date loan should mature
    /// @param _period How often payments are required
    /// @param _totalBalance Total eth transfered once loan matures
    /// @return The Id of the newly-created PeriodicLoan, ie it's index in the list
    function _createLoan(
        uint256 _dueDate,
        uint256 _period,
        uint256 _totalBalance
    ) public returns (uint256) {
        uint256 id = loans.length;
        // figure out minimum payment such that _totalBalance is payed
        uint256 duration = _dueDate - block.timestamp;
        require(duration >= _period, "Period too small");
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
        emit LoanCreated(id, msg.sender, _totalBalance, _dueDate);
        return id;
    }

    /// @notice Allows user to service their loan with a set amount of ether. Allows
    ///         for overserving, closes the loan if it's completed, and doesn't care
    ///         about lateness of payment.
    /// @param _id ID or index of loan you want to service
    /// @param _with Amount of eth the loan has been serviced by
    function _serviceLoan(uint256 _id, uint256 _with) public {
        // get, check loan
        PeriodicLoan storage l = loans[_id];
        require(l.active, "Referenced token is not active");

        // figure out periods covered by payment
        uint256 fullPayment = _with + serviceReceived[_id];
        uint256 acceptedPayment = 0;
        uint256 periodsCovered = fullPayment / l.minimumPayment;
        // check if loan is fully paid
        if (l.balance <= fullPayment) {
            payable(l.creditor).transfer(l.balance);
            _completeLoan(l);
            if (l.balance < fullPayment) {
                payable(l.borrower).transfer(fullPayment - l.balance);
            }
            emit LoanCompleted(_id, l.borrower);
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

    /// @notice Cancels the given loan id, performing the required checks
    /// @param _id Id of loan you want to cancel
    function _cancelLoan(uint256 _id) public {
        // get, check loan
        PeriodicLoan storage l = loans[_id];
        require(l.active, "Referenced token is not active");

        _completeLoan(l);
    }

    function _completeLoan(PeriodicLoan storage l) internal {
        l.active = false;
        // TODO: release collateral
    }

    receive() external payable {}
}
