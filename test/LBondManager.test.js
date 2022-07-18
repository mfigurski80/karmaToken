const LBondManager = artifacts.require('LBondManager');

const { buildBondBytes } = require('./utils');

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
      assert.equal(+r, 0xA);

      // r = await instance.readCouponSize(
        // // 32 -- 2 bit mult is *1* + 30 bit coupon_size is *10* (0x4000000A)
        // '0xFF4000000A'
      // );
      // assert.equal(+r, 0xA * 1_000_000_000);

      r = await instance.readCouponSize('0xFF00000078'); 
      assert.equal(+r, 0x78); 
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
        let r = await instance.readPeriodDuration(
          // 32 + 48 bit offset (0xFFFFFFFFFFFFFFFFFFFF)
          // 16 bits -- 2 bits for mult is *0*, 14 for value is *15* (0x000F)
          '0xFFFFFFFFFFFFFFFFFFFF0010'
        );
        assert.equal(r.toNumber(), 16, 'Period Duration is read as 16');

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

  describe('generic read/write bond', () => {

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

    it('reads generated bytes correctly', async () => {
      const now = Math.floor(Date.now() / 1000);
      const [alp, bet] = buildBondBytes({
        flag: false,
        currencyRef: 0, 
        nPeriods: 10, curPeriod: 0,
        startTime: now, periodDuration: 60 * 60,
        couponSize: 10, faceValue: 10,
        beneficiary: accounts[0], minter: accounts[0]
      });
      const r = await instance.readBond(alp, bet);
      assert.equal(r.couponSize, 10);
      assert.equal(r.faceValue, 10);
      assert.equal(r.minter, accounts[0]);
      assert.equal(r.flag, false);
      assert.equal(r.periodDuration, 60 * 60);
      assert.equal(r.startTime, now);
    });

    it('can generate both slots', async () => {
      const now = Math.floor(Date.now() / 1000);
      const alp = await instance.buildAlpha(
        true, 10, 12, 1, 2, accounts[0]
      );
      const bet = await instance.buildBeta(
        100, now, 60*60, accounts[1]
      );
      const b = await instance.readBond(alp, bet);
      // console.log('         [][ Coup ][nP][cP][ cur][     beneficiary ...');
      // console.log(`Alpha: ${alp}`);
      // console.log('         [ face ][   start  ][Pd][     minter ...');
      // console.log(`Beta:  ${bet}`);
      // console.log(b);
      assert.equal(b.flag, true);
      assert.equal(b.couponSize, 10);
      assert.equal(b.nPeriods, 12);
      assert.equal(b.curPeriod, 1);
      assert.equal(b.currencyRef, 2);
      assert.equal(b.beneficiary, accounts[0]);
      assert.equal(b.faceValue, 100);
      assert.equal(b.startTime, now);
      assert.equal(b.periodDuration, 60*60);
      assert.equal(b.minter, accounts[1]);
    });

    it('encodes slots correctly', async () => {
      const now = Math.floor(Date.now() / 1000);
      const alp = await instance.buildAlpha(
        false, 120, 365, 0, 0, accounts[1]
      );
      const bet = await instance.buildBeta(
        1000, now, 60*60*24, accounts[0]
      );
      const b = await instance.readBond(alp, bet);
      console.log('         [][ Coup ][nP][cP][ cur][     beneficiary ...');
      console.log(`Alpha: ${alp}`);
      // console.log('         [ face ][   start  ][Pd][     minter ...');
      // console.log(`Beta:  ${bet}`);
      assert.equal(b.couponSize, 120);
    });

  });

});
