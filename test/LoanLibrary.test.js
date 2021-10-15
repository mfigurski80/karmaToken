const LoanLibrary = artifacts.require('LoanLibrary');

contract('LoanLibrary', accounts => {
    let instance;

    before(async () => {
        instance = await LoanLibrary.new();
    });
    
    it('should be able to read format and flag from alpha slot', async() => {
        const r = await instance.readFormatAndFlag(
            // 8  -- 7 bit format is *0* + 1 bit flag is *true* (0x01)
            '0x01'
        );
        assert.isTrue(r.flag);
        assert.equal(r.format, 0);
    });

    it('should be able to read coupon size', async() => {
        const r = await instance.readCouponSize(
            // 8 bit offset (0xFF)
            // 32 -- 2 bit mult is *0* + 30 bit coupon_size is *10* (0x0000000A)
            '0xFF0000000A'
        );
        assert.equal(r, 10);
    });

    it('should be able to read period data', async() => {
        const r = await instance.readPeriodData(
            // 8+32 bit offset (0xFFFFFFFFFF)
            // 16 -- n_periods is *10* (0x000A)
            // 16 -- cur_period is *4* (0x0004)
            '0xFFFFFFFFFF000A0004'
        );
        assert.equal(r.n_periods, 10);
        assert.equal(r.cur_period, 4);
    })

    it('should be able to read currency reference', async() => {
        const r = await instance.readCurrency(
            // 8+32+16+16 bit offset (0xFFFFFFFFFFFFFFFFFF)
            // 24 -- currency is *16* (0x000010) 
            '0xFFFFFFFFFFFFFFFFFF000010'
        );
        assert.equal(r.toNumber(), 16, "Currency is read as 16");
    });

    it('should be able to read beneficiary address', async() => {
        address = '0000000000000000000000000000000000000000';
        const r = await instance.readBeneficiary(
            // 8+32+16+16+24 bit offset (0xFFFFFFFFFFFFFFFFFFFFFFFF)
            // 160 -- beneficiary is *0x0000000000000000000000000000000000000000*
            `0xFFFFFFFFFFFFFFFFFFFFFFFF${address}`
        );
        assert.equal(r, `0x${address}`, `Beneficiary is read as ${address}`);
    })

})