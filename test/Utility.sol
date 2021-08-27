// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../contracts/LoanManager.sol";
import "../contracts/CollateralManager.sol";

abstract contract Utility {
    // ACTUAL UTILITIES

    function _getPeriodicLoan(uint256 id, LoanManager loanManager)
        internal
        view
        returns (PeriodicLoan memory)
    {
        PeriodicLoan memory l;
        (
            l.active,
            l.beneficiary,
            l.borrower,
            l.period,
            l.nextServiceTime,
            l.balance,
            l.minimumPayment
        ) = loanManager.loans(id);
        return l;
    }

    // TYPE CONVERSIONS

    function address2str(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + (_i % 10)));
            _i /= 10;
        }
        return string(bstr);
    }
}
