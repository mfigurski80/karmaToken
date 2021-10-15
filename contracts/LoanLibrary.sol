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
        bytes1 packedFormatFlag = bytes1(alp);
        format = uint8(packedFormatFlag >> 1); // get first 7 bits
        require(format == supportedFormat(), "Library: unsupported format");
        flag = uint8(packedFormatFlag & 0x01) == 1; // get last bit
    }

    function readCouponSize(bytes32 alp)
        public
        pure
        returns (uint256 couponSize)
    {
        // read mult + coupon size (32 bits)
        bytes4 couponData = bytes4(alp << 8); // skip 8 bits, get 32 bits
        uint8 couponMult = uint8(bytes1(couponData)) >> 6; // get first 2 bits
        couponSize = uint32(couponData) & 0x3F;
        if (couponMult == 1) couponSize *= 1 gwei;
        if (couponMult == 2) couponSize *= 1 ether / 1000;
        if (couponMult == 3) couponSize *= 1 ether;
    }

    function readPeriodData(bytes32 alp)
        public
        pure
        returns (uint16 nPeriods, uint16 curPeriod)
    {
        // read nPeriods (16 bits)
        nPeriods = uint16(bytes2(alp << (8 + 32)));
        // read curPeriod (16 bits)
        curPeriod = uint16(bytes2(alp << (8 + 32 + 16)));
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
