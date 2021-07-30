// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0;

import "./types/PeriodicLoanStruct.sol";

contract LoanManager {
    PeriodicLoan[] public loans;
    mapping(uint256 => uint256) public serviceReceived;

    // mapping(uint256 => address) public loanToOwner;
    // mapping(address => uint256) public ownerLoanCount;

    event LoanCreated(
        uint256 id,
        address creator,
        uint256 amount,
        uint256 dueDate
    );
    event LoanServiced(uint256 id, address servicer, uint256 amount);
    event LoanCompleted(uint256 id, address servicer);

    function _createLoan(
        uint256 _dueDate,
        uint256 _period,
        uint256 _totalBalance
    ) internal returns (uint256) {
        uint256 id = loans.length;
        // figure out minimum payment such that _totalBalance is payed
        require(_dueDate - block.timestamp >= _period, "Period too small");
        uint256 nPeriods = ((_dueDate - block.timestamp) / _period);
        uint256 minPayment = _dueDate / nPeriods;
        if ((_dueDate - block.timestamp) % nPeriods != 0) {
            minPayment++;
        }
        // TODO: figure out collateral transfers
        Collateral[] memory collateral;
        // add loan
        loans.push(
            PeriodicLoan(
                false,
                msg.sender,
                msg.sender,
                _period,
                block.timestamp + _period,
                _totalBalance,
                minPayment,
                collateral
            )
        );
        emit LoanCreated(id, msg.sender, _totalBalance, _dueDate);
        return id;
    }

    function _serviceLoan(
        uint256 _id,
        uint256 _with,
        address _by
    ) internal {
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
                payable(_by).transfer(fullPayment - l.balance);
            }
            emit LoanCompleted(_id, l.borrower);
            return;
        }
        // else if not fully paid...
        if (periodsCovered > 0) {
            // find next service time
            l.nextServiceTime = l.nextServiceTime + periodsCovered * l.period;
            // update balance with period's payments
            acceptedPayment = l.period * periodsCovered;
            payable(l.creditor).transfer(acceptedPayment);
            l.balance -= acceptedPayment;
            emit LoanServiced(_id, l.borrower, acceptedPayment);
        }
        // return overflow payment to storage
        serviceReceived[_id] = fullPayment - acceptedPayment;
    }

    function _cancelLoan(uint256 _id) internal {
        // get, check loan
        PeriodicLoan storage l = loans[_id];
        require(l.active, "Referenced token is not active");

        _completeLoan(l);
    }

    function _completeLoan(PeriodicLoan storage l) internal {
        l.active = false;
        // TODO: release collateral
    }
}
