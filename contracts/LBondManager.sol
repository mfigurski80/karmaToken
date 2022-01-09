// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

struct Bond {
    bool flag;
    uint16 nPeriods;
    uint16 curPeriod;
    uint16 claimedPeriods;
    uint32 currencyRef;
    uint64 startTime;
    uint64 periodDuration;
    uint256 couponSize;
    uint256 faceValue;
    // address beneficiary;
    address minter;
}

library LBondManager {
    function supportedFormat() public pure returns (uint8) {
        // FORMAT IMPLIED:
        // A (14 bytes): [1 byte format + flag][4 bytes coupon size][2 bytes nPeriods][2 bytes curPeriod][3 bytes currencyRef][2 bytes withdrawnPeriods]
        // B (32 bytes): [4 bytes face value][6 bytes start time][2 bytes period duration][20 bytes minter]
        return 0;
    }

    /* ###################
     *    READING DATA
     * ################### */

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

    // function readBeneficiary(bytes32 alp)
    //     public
    //     pure
    //     returns (address beneficiary)
    // {
    //     // read beneficiary (160 bits, 20 bytes)
    //     return address(bytes20(alp << (8 + 32 + 16 + 16 + 24)));
    // }

    function readClaimedPeriods(bytes32 alp)
        public
        pure
        returns (uint16 claimedPeriods)
    {
        // read number of periods withdrawn by owner
        claimedPeriods = uint16(bytes2(alp << (8 + 32 + 16 + 16 + 24)));
    }

    // READING BETA SLOT

    function readFaceValue(bytes32 bet)
        public
        pure
        returns (uint256 faceValue)
    {
        // read face value (32 bits, 4 bytes)
        bytes4 valueData = bytes4(bet);
        uint8 valueMult = uint8(bytes1(bet)) >> 6; // get first two bits
        faceValue = uint32(valueData) & 0x3FFFFFFF; // clear first two bits
        if (valueMult == 1) faceValue *= 1 gwei;
        if (valueMult == 2) faceValue *= 1 ether / 1000;
        if (valueMult == 3) faceValue *= 1 ether;
    }

    function readStartTime(bytes32 bet) public pure returns (uint64 startTime) {
        // read start time (48 bits, 6 bytes)
        return uint64(bytes8(bytes6(bet << (32))) >> 16); // skip face value 32 bits
    }

    function readPeriodDuration(bytes32 bet)
        public
        pure
        returns (uint64 periodDuration)
    {
        // read period duration (16 bits, 2 bytes)
        // 2 bits for multiplier
        bytes2 durationData = bytes2(bet << (32 + 48)); // skip face value and start time
        uint8 durationMult = uint8(bytes1(durationData)) >> 6; // get first two bits
        periodDuration = uint16(durationData) & 0x3FFF; // clear first two bits
        if (durationMult == 1) periodDuration *= 60; // in minutes?
        if (durationMult == 2) periodDuration *= 60 * 60; // in hours?
        if (durationMult == 3) periodDuration *= 60 * 60 * 24; // in days?
    }

    function readMinter(bytes32 bet) public pure returns (address minter) {
        return address(bytes20(bet << (32 + 48 + 16)));
    }

    /* ###################
     *    WRITING DATA
     * ################### */

    // WRITING ALPHA SLOT

    function writeFlag(bytes32 alp, bool flag) public pure returns (bytes32) {
        alp &= 0xFEFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // clear flag bit
        return alp | bytes32(bytes1(flag ? 1 : 0));
    }

    function writeCurPeriod(bytes32 alp, uint16 curPeriod)
        public
        pure
        returns (bytes32)
    {
        alp &= 0xFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        return alp | (bytes32(bytes2(curPeriod)) >> (8 + 32 + 16));
    }

    // function writeBeneficiary(bytes32 alp, address beneficiary)
    //     public
    //     pure
    //     returns (bytes32)
    // {
    //     alp &= 0xFFFFFFFFFFFFFFFFFFFFFFFF0000000000000000000000000000000000000000;
    //     return alp | (bytes32(bytes20(beneficiary)) >> (8 + 32 + 16 + 16 + 24));
    // }

    function writeClaimedPeriods(bytes32 alp, uint16 claimedPeriods)
        public
        pure
        returns (bytes32)
    {
        alp &= 0xFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        return
            (bytes32(bytes2(claimedPeriods)) >> (8 + 32 + 16 + 16 + 24)) | alp;
    }

    // NO DATA-SPECIFIC WRITING NEEDS TO HAPPEN IN BETA SLOT

    /* ###################
     *    Generic Reads
     * ################### */

    function fillBondFromAlpha(bytes32 alp, Bond memory b)
        public
        pure
        returns (Bond memory)
    {
        (, b.flag) = readFormatAndFlag(alp);
        b.couponSize = readCouponSize(alp);
        (b.nPeriods, b.curPeriod) = readPeriodData(alp);
        b.claimedPeriods = readClaimedPeriods(alp);
        b.currencyRef = readCurrency(alp);
        // b.beneficiary = readBeneficiary(alp);
        return b;
    }

    function fillBondFromBeta(bytes32 bet, Bond memory b)
        public
        pure
        returns (Bond memory)
    {
        b.faceValue = readFaceValue(bet);
        b.startTime = readStartTime(bet);
        b.periodDuration = readPeriodDuration(bet);
        b.minter = readMinter(bet);
        return b;
    }

    function readBond(bytes32 alp, bytes32 bet)
        public
        pure
        returns (Bond memory b)
    {
        b = fillBondFromAlpha(alp, b);
        b = fillBondFromBeta(bet, b);
    }
}
