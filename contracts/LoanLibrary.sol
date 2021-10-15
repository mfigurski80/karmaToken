// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract LoanLibrary {
    function supportedFormat() public pure returns (uint8) {
        return 0;
    }

    // READING ALPHA SLOT
    function readFormatAndFlag(bytes32 alp)
        public
        pure
        returns (uint8 format, bool flag)
    {
        // read format + flag (8 bits)
        bytes1 packed_format_flag = bytes1(alp);
        uint8 format = uint8(packed_format_flag >> 1); // get first 7 bits
        require(format == supportedFormat(), "Library: unsupported format");
        bool flag = uint8(packed_format_flag & 0x01) == 1; // get last bit
        return (format, flag);
    }

    function readCouponSize(bytes32 alp)
        public
        pure
        returns (uint256 coupon_size)
    {
        // read mult + coupon size (32 bits)
        bytes4 coupon_data = bytes4(alp << 8); // skip 8 bits, get 32 bits
        uint8 coupon_mult = uint8(bytes1(coupon_data)) >> 6; // get first 2 bits
        uint256 coupon_size = uint32(coupon_data) & 0x3F;
        if (coupon_mult == 1) coupon_size *= 1 gwei;
        if (coupon_mult == 2) coupon_size *= 1 ether / 1000;
        if (coupon_mult == 3) coupon_size *= 1 ether;
        return coupon_size;
    }

    function readPeriodData(bytes32 alp)
        public
        pure
        returns (uint16 n_periods, uint16 cur_period)
    {
        // read n_periods (16 bits)
        uint16 n_periods = uint16(bytes2(alp << (8 + 32)));
        // read cur_period (16 bits)
        uint16 cur_period = uint16(bytes2(alp << (8 + 32 + 16)));
        return (n_periods, cur_period);
    }

    function readCurrency(bytes32 alp) public pure returns (uint32 currency) {
        // read currency (24 bits)
        return uint32(bytes4(bytes3(alp << (8 + 32 + 16 + 16))) >> 8);
    }

    function readBeneficiary(bytes32 alp)
        public
        pure
        returns (address beneficiary)
    {
        // read beneficiary (160 bits, 20 bytes)
        return address(bytes20(alp << (8 + 32 + 16 + 16 + 24)));
    }

    // TODO: READING BETA SLOT

    function readLoan(bytes32 alp, bytes32 bet) public pure {}
}
