const LBondManager = artifacts.require('LBondManager');

contract('LBondManager', accounts => {
    let instance;

    before(async () => {
        instance = await LBondManager.new();
    });
    
    describe('reading alpha slot', () => {
        // TODO: ensure we're reading multipliers properly

        it('reads format and flag', async() => {
            const r = await instance.readFormatAndFlag(
                // 8  -- 7 bit format is *0* + 1 bit flag is *true* (0x01)
                '0x01'
            );
            assert.isTrue(r.flag);
            assert.equal(r.format, 0);
            // TODO: test format error
        });
        
        it('reads coupon size', async() => {
            let r = await instance.readCouponSize(
                // 8 bit offset (0xFF)
                // 32 -- 2 bit mult is *0* + 30 bit coupon_size is *10* (0x0000000A)
                '0xFF0000000A'
            );
            assert.equal(r, 10);

            r = await instance.readCouponSize(
                // 32 -- 2 bit mult is *1* + 30 bit coupon_size is *10* (0x4000000A)
                '0xFF4000000A'
            );
            assert.equal(r.toNumber(), 10 * 1_000_000_000);

        });
        
        it('reads period data', async() => {
            const r = await instance.readPeriodData(
                // 8+32 bit offset (0xFFFFFFFFFF)
                // 16 -- n_periods is *10* (0x000A)
                // 16 -- cur_period is *4* (0x0004)
                '0xFFFFFFFFFF000A0004'
            );
            assert.equal(r.nPeriods, 10);
            assert.equal(r.curPeriod, 4);
        })
    
        it('reads currency reference', async() => {
            const r = await instance.readCurrency(
                // 8+32+16+16 bit offset (0xFFFFFFFFFFFFFFFFFF)
                // 24 -- currency is *16* (0x000010) 
                '0xFFFFFFFFFFFFFFFFFF000010'
            );
            assert.equal(r.toNumber(), 16, 'Currency is read as 16');
        });
        
        it('reads beneficiary address', async() => {
            address = '0000000000000000000000000000000000000000';
            const r = await instance.readBeneficiary(
                // 8+32+16+16+24 bit offset (0xFFFFFFFFFFFFFFFFFFFFFFFF)
                // 160 -- beneficiary is *0x0000000000000000000000000000000000000000*
                `0xFFFFFFFFFFFFFFFFFFFFFFFF${address}`
            );
            assert.equal(r, `0x${address}`, `Beneficiary is read as ${address}`);
        });
    });

    describe('reading beta slot', () => {
        // TODO: ensure we're reading multipliers properly

        it('reads face value', async () => {
            const r = await instance.readFaceValue(
                // 32 bits -- face value is *100* (0x00000064)
                '0x00000064'
            );
            assert.equal(r.toNumber(), 100, 'Face Value is read as 100');
        });

        it('reads start time', async () => {
            const r = await instance.readStartTime(
                // 32 bit offset (0xFFFFFFFF)
                // 48 bits -- start time is 1634280054 - 0x000061692276
                '0xFFFFFFFF000061692276'
            );
            assert.equal(r.toNumber(), 1634280054, 'Start Time is read to Oct 15th');
        });

        it('reads period duration', async () => {
            const r = await instance.readPeriodDuration(
                // 32 + 48 bit offset (0xFFFFFFFFFFFFFFFFFFFF)
                // 16 bits -- 2 bits for mult is *0*, 14 for value is *15* (0x000F)
                '0xFFFFFFFFFFFFFFFFFFFF000F'
            );
            // assert.equal(r, '');
            assert.equal(r.toNumber(), 15, 'Period Duration is read as 15');
        });

        it('reads minter address', async () => {
            address = '0000000000000000000000000000000000000000';
            const r = await instance.readMinter(
                // 32 + 48 + 16 bit offset (0xFFFFFFFFFFFFFFFFFFFFFFFF)
                // 160 bits 
                `0xFFFFFFFFFFFFFFFFFFFFFFFF${address}`
            );
            assert.equal(r, `0x${address}`, `Minter is read as ${address}`);
        });
    });

    describe('writing alpha slot', () => {

        const maxVal = '0x01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF';

        it('writes flag', async () => {
            // write true flag
            let r = await instance.writeFlag(maxVal, true);
            let check = await instance.readFormatAndFlag(r);
            assert.isTrue(check.flag);
            // write false flag
            r = await instance.writeFlag(maxVal, false);
            check = await instance.readFormatAndFlag(r);
            assert.isFalse(check.flag);
        });

        it('writes curPeriod', async () => {
            let r = await instance.writeCurPeriod(maxVal, 4);
            let check = await instance.readPeriodData(r);
            assert.equal(check.curPeriod, 4);
        });

        it('writes beneficiary', async () => {
            let r = await instance.writeBeneficiary(maxVal, accounts[0]);
            let check = await instance.readBeneficiary(r);
            assert.equal(check, accounts[0]);
        });
        
    });
    
    describe('generic read bond', () => {

        it('reads a bond', async () => {
            const alp = '0x00FFFFFFFFFFFFFFFFFFFFFF0000000000000000000000000000000000000000';
            const bet = '0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF';

            const r = await instance.readBond(alp, bet);

            let check = await instance.readCouponSize(alp);
            assert.equal(check, r.couponSize, 'Coupon Size is read as expected');
            check = await instance.readMinter(bet);
            assert.equal(check, r.minter, 'Minter is read as expected');
            check = await instance.readPeriodDuration(bet);
            assert.equal(check, r.periodDuration, 'Period Duration is read as expected');
        });

    });

});