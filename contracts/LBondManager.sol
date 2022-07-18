// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

struct Bond {
    bool flag;
    uint32 currencyRef;
    uint16 nPeriods;
    uint16 curPeriod;
    uint64 startTime;
    uint64 periodDuration;
    uint256 couponSize;
    uint256 faceValue;
    address beneficiary;
    address minter;
}

/**
 * @title 🗜️ Library containing utils for reading and writing bonds
 * @notice Bonds are bit-compressed in storage -- must be read by
 * this library
 */
library LBondManager {
    /**
     * @dev describes the 7-bit format id that LBondManager accepts
     */
    function supportedFormat() public pure returns (uint8) {
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
        couponSize = uint32(couponData) & 0x3FFFFFFF;
        if (couponMult == 1) couponSize *= 1 gwei;
        else if (couponMult == 2) couponSize *= 1 ether / 1000;
        else if (couponMult == 3) couponSize *= 1 ether;
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

    function writeBeneficiary(bytes32 alp, address beneficiary)
        public
        pure
        returns (bytes32)
    {
        alp &= 0xFFFFFFFFFFFFFFFFFFFFFFFF0000000000000000000000000000000000000000;
        return alp | (bytes32(bytes20(beneficiary)) >> (8 + 32 + 16 + 16 + 24));
    }

    // NO DATA-SPECIFIC WRITING NEEDS TO HAPPEN IN BETA SLOT

    /* ###################
     *    Generic Reads + Writes
     * ################### */

    function fillBondFromAlpha(bytes32 alp, Bond memory b)
        public
        pure
        returns (Bond memory)
    {
        (, b.flag) = readFormatAndFlag(alp);
        b.couponSize = readCouponSize(alp);
        (b.nPeriods, b.curPeriod) = readPeriodData(alp);
        b.currencyRef = readCurrency(alp);
        b.beneficiary = readBeneficiary(alp);
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

    /**
     * @notice Read full bond from given alpha and beta parts
     * @param alp Alpha part of the bond data
     * @param bet Beta part of the bond data
     */
    function readBond(bytes32 alp, bytes32 bet)
        public
        pure
        returns (Bond memory b)
    {
        b = fillBondFromAlpha(alp, b);
        b = fillBondFromBeta(bet, b);
    }

    /**
     * @notice Build bond alpha bytes from parts
     * @param flag Boolean describing if bond is defaulted
     * (usually starts as false)
     * @param couponSize Amount to pay each period
     * @param nPeriods Number of periods until completion
     * @param curPeriod Current period of the bond (usually
     * starts at 0)
     * @param currencyRef Id of currency to expect payments
     * to be made in
     * @param beneficiary Account address of recipient of all
     * payments
     * @return alp Alpha bytes32 used to represent the first
     * part of the bond
     * @dev Note that setting curPeriod to something greater
     * than nPeriods means bond will be immediately interpreted
     * as 'completed'.
     * @dev Some fields may be encoded with smaller resolution
     * than may be apparent to decrease storage space -- these
     * include: couponSize
     */
    function buildAlpha(
        bool flag,
        uint256 couponSize,
        uint16 nPeriods,
        uint16 curPeriod,
        uint32 currencyRef,
        address beneficiary
    ) public pure returns (bytes32 alp) {
        uint8 flagNFormat = flag ? 1 : 0;

        uint32 couponSizeMult = 0;
        uint32 couponSizeEnc = uint32(couponSize);
        if (couponSize > (1 ether * 2**30) / 1000) {
            couponSizeMult = 3;
            couponSizeEnc = uint32(couponSize / 1 ether);
        } else if (couponSize > 1 gwei * 2**30) {
            couponSizeMult = 2;
            couponSizeEnc = uint32(couponSize / (1 ether / 1000));
        } else if (couponSize > 2**30) {
            couponSizeMult = 1;
            couponSizeEnc = uint32(couponSize / 1 gwei);
        }
        require(
            couponSizeEnc < 2**30,
            "LBondManager: couponSize too large to encode"
        );
        couponSizeEnc = (couponSizeEnc) | (couponSizeMult << 30);

        require(
            currencyRef < 2**24,
            "LBondManager: currencyRef too large to encode"
        );
        uint24 currencyRefEnc = uint24(currencyRef);

        return
            bytes32(
                abi.encodePacked(
                    flagNFormat,
                    couponSizeEnc,
                    nPeriods,
                    curPeriod,
                    currencyRefEnc,
                    beneficiary
                )
            );
    }

    /**
     * @notice BUild bond beta bytes from parts
     * @param faceValue Amount to pay at end of bond
     * @param startTime Time this bond begins at, in
     * seconds since 1970
     * @param periodDuration How long between each period of
     * the bond, in seconds
     * @param minter Account address of the bond creator
     * @dev Some fields may be encoded with smaller resolution
     * than may be apparent to decrease storage space -- these
     * include: faceValue and periodDuration
     */
    function buildBeta(
        uint256 faceValue,
        uint64 startTime,
        uint64 periodDuration,
        address minter
    ) public pure returns (bytes32 bet) {
        uint32 faceValueMult = 0;
        uint32 faceValueEnc = uint32(faceValue);
        if (faceValue > 2**30) {
            faceValueMult = 1;
            faceValueEnc = uint32(faceValue / 1 gwei);
        }
        if (faceValue > 1 gwei * 2**30) {
            faceValueMult = 2;
            faceValueEnc = uint32(faceValue / (1 ether / 1000));
        }
        if (faceValue > (1 ether * 2**30) / 1000) {
            faceValueMult = 3;
            faceValueEnc = uint32(faceValue / 1 ether);
        }
        require(
            faceValueEnc < 2**30,
            "LBondManager: faceValue too large to encode"
        );
        faceValueEnc = (faceValueEnc) | (faceValueMult << 30);

        uint48 startTimeEnc = uint48(startTime);
        require(
            startTime < 2**48,
            "LBondManager: startTime too large to encode"
        );

        uint16 periodDurationMult = 0;
        uint16 periodDurationEnc = uint16(periodDuration);
        if (periodDuration > 2**14) {
            periodDurationMult = 1;
            periodDurationEnc = uint16(periodDuration / 60);
        }
        if (periodDuration > 60 * 2**14) {
            periodDurationMult = 2;
            periodDurationEnc = uint16(periodDuration / (60 * 60));
        }
        if (periodDuration > 60 * 60 * 2**14) {
            periodDurationMult = 3;
            periodDurationEnc = uint16(periodDuration / (60 * 60 * 24));
        }
        require(
            periodDurationEnc < 2**14,
            "LBondManager: periodDuration too large to encode"
        );
        periodDurationEnc = (periodDurationEnc) | (periodDurationMult << 14);

        return
            bytes32(
                abi.encodePacked(
                    faceValueEnc,
                    startTimeEnc,
                    periodDurationEnc,
                    minter
                )
            );
    }

    function buildBondBytes(Bond calldata b)
        external
        pure
        returns (bytes32 alp, bytes32 bet)
    {
        alp = buildAlpha(
            b.flag,
            b.couponSize,
            b.nPeriods,
            b.curPeriod,
            b.currencyRef,
            b.beneficiary
        );
        bet = buildBeta(b.faceValue, b.startTime, b.periodDuration, b.minter);
    }
}
