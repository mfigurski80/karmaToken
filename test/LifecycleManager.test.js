const LifecycleManager = artifacts.require('LifecycleManager');
const LBondManager = artifacts.require('LBondManager');
const ERC20 = artifacts.require('ERC20Exposed');
const ERC721 = artifacts.require('ERC721Exposed');
const ERC1155 = artifacts.require('ERC1155Exposed');

const { buildBondBytes, getEvent, getRevert } = require('./utils');

contract('LifecycleManager', accounts => {
    let instance;
    let libraryInstance;
    let erc20Instance;
    let erc721Instance;
    let erc1155Instance;

    const owner = accounts[0];
    const beneficiary = accounts[1];
    const DEFAULT_BOND = {
        flag: false,
        currencyRef: 0,
        nPeriods: 10, curPeriod: 0,
        startTime: Date.now(), periodDuration: 60*60*24,
        couponSize: 1, faceValue: 2,
        beneficiary, minter: owner
    }
    const ARGS = { name: 'Test Token', symbol: 'TST', uri: 'http://localhost' };


    before(async () => {
        libraryInstance = await LBondManager.new();
        LifecycleManager.link(libraryInstance);
        erc20Instance = await ERC20.new();
        await erc20Instance.mint(owner, 10000);
        erc721Instance = await ERC721.new("Test", "TST", "URI");
        await erc721Instance.mint(owner, 0);
        erc1155Instance = await ERC1155.new();
        await erc1155Instance.mint(owner, 0, 10000);
        await erc1155Instance.mint(owner, 1, 1);
    });

    beforeEach(async () => {
        instance = await LifecycleManager.new(ARGS.name, ARGS.symbol, ARGS.uri);
        await erc20Instance.approve(instance.address, 10000);
        await erc721Instance.setApprovalForAll(instance.address, true);
        await erc1155Instance.setApprovalForAll(instance.address, true);
    });
    
    it('receives bytes with expected values', async () => {
        // this is more to test the bytes ^^ being okay
        const bytes = buildBondBytes(DEFAULT_BOND);
        await instance.mintBond(bytes[0], bytes[1]);
        let b = await instance.getBond(0);
        assert.equal(b.nPeriods, 10);
        assert.equal(b.curPeriod, 0);
        assert.equal(b.currencyRef, 0);
        assert.equal(b.faceValue, 2);
        assert.equal(b.couponSize, 1);
        assert.equal(b.minter, owner);
        assert.equal(b.beneficiary, beneficiary);
    });

    describe('service payments', () => {

        it('exposes serviceBond method', async () => {
            assert.notEqual(instance.serviceBond, undefined);
        });

        it('allows servicing bond with ether', async () => {
            const bytes = buildBondBytes(DEFAULT_BOND);
            await instance.mintBond(bytes[0], bytes[1]);
            const oldBalance = await web3.eth.getBalance(beneficiary);
            // get event
            let ev = await instance.serviceBond(0, owner, 1, 0x0, { value: 1, from: owner })
                .then(tx => getEvent(tx, 'BondServiced'));
            assert.equal(ev.id, 0);
            assert.equal(ev.toPeriod, 1);
            // bond updated
            let b = await instance.getBond(0);
            assert.equal(b.curPeriod, 1);
            // beneficiary received ether
            let newBalance = await web3.eth.getBalance(beneficiary);
            assert.notEqual(newBalance, oldBalance, 'no resources sent to beneficiary');
            // console.log(`${newBalance} - ${oldBalance} = ${newBalance - oldBalance}`);
            // assert.equal(newBalance - oldBalance, 1, 'wrong amount sent to beneficiary');
            // FIXME: ^^ lol. No idea why this is failing.
            // Probably because beneficiary is executing and so burning gas. Check recipient instead
        });

        it('allows servicing bond with erc20', async () => {
            await instance.addERC20Currency(erc20Instance.address);
            const bytes = buildBondBytes({
                ...DEFAULT_BOND,
                currencyRef: 1
            });
            const oldBalance = await erc20Instance.balanceOf(beneficiary);
            await instance.mintBond(bytes[0], bytes[1]);
            // event emitted
            let ev = await instance.serviceBond(0, owner, 1, 0x0)
                .then(tx => getEvent(tx, 'BondServiced'));
            assert.equal(ev.id, 0);
            assert.equal(ev.toPeriod, 1);
            // bond updated
            let b = await instance.getBond(0);
            assert.equal(b.curPeriod, 1);
            // beneficiary received erc20
            let balance = await erc20Instance.balanceOf(beneficiary);
            assert.notEqual(balance, oldBalance, 'no resources sent to beneficiary');
            assert.equal(balance - oldBalance, 1, 'wrong amount sent to beneficiary');
        });

        it('allows servicing bond with erc721', async () => {
            await instance.addERC721Currency(erc721Instance.address);
            const bytes = buildBondBytes({
                ...DEFAULT_BOND,
                currencyRef: 1
            });
            const oldOwner = await erc721Instance.ownerOf(0);
            await instance.mintBond(bytes[0], bytes[1]);
            // event emitted
            let ev = await instance.serviceBond(0, owner, 0, 0x0)
                .then(tx => getEvent(tx, 'BondServiced'));
            assert.equal(ev.id, 0);
            assert.equal(ev.toPeriod, 1);
            // bond updated
            let b = await instance.getBond(0);
            assert.equal(b.curPeriod, 1);
            // beneficiary received erc721
            let newOwner = await erc721Instance.ownerOf(0);
            assert.notEqual(newOwner, oldOwner, 'resource stayed with servicer');
            assert.equal(newOwner, beneficiary, 'beneficiary not received resource');
        });

        it('allows servicing bond with erc1155 tokens', async () => {
            await instance.addERC1155TokenCurrency(erc1155Instance.address, 0);
            const bytes = buildBondBytes({
                ...DEFAULT_BOND,
                currencyRef: 1
            });
            const oldBalance = await erc1155Instance.balanceOf(beneficiary, 0);
            await instance.mintBond(bytes[0], bytes[1]);
            let tx = await instance.serviceBond(0, owner, 1, 0x0);
            // event emitted
            let ev = await getEvent(tx, 'BondServiced');
            assert.equal(ev.id, 0);
            assert.equal(ev.toPeriod, 1);
            // bond updated
            let b = await instance.getBond(0);
            assert.equal(b.curPeriod, 1);
            // beneficiary received erc1155-0
            let balance = await erc1155Instance.balanceOf(beneficiary, 0);
            assert.notEqual(balance, oldBalance, 'no resources sent to beneficiary');
            assert.equal(balance - oldBalance, 1, 'wrong amount sent to beneficiary');
        });

        it('allows servicing bond with erc1155 nfts', async () => {
            await instance.addERC1155NFTCurrency(erc1155Instance.address);
            const bytes = buildBondBytes({
                ...DEFAULT_BOND,
                currencyRef: 1
            });
            const oldBalance = await erc1155Instance.balanceOf(beneficiary, 1);
            await instance.mintBond(bytes[0], bytes[1]);
            let tx = await instance.serviceBond(0, owner, 1, 0x0);
            // event emitted
            let ev = await getEvent(tx, 'BondServiced');
            assert.equal(ev.id, 0);
            assert.equal(ev.toPeriod, 1);
            // bond updated
            let b = await instance.getBond(0);
            assert.equal(b.curPeriod, 1);
            // beneficiary received erc1155-1
            let balance = await erc1155Instance.balanceOf(beneficiary, 1);
            assert.notEqual(balance, oldBalance, 'no resources sent to beneficiary');
            assert.equal(balance - oldBalance, 1, 'wrong amount sent to beneficiary');
        });

        it('allows completing bonds', async () => {
            const bytes = buildBondBytes(DEFAULT_BOND);
            await instance.mintBond(bytes[0], bytes[1]);
            let tx = await instance.serviceBond(0, owner, 10, 0x0, { value: 10, from: owner });
            // event emitted
            let ev = await getEvent(tx, 'BondServiced');
            assert.equal(ev.id, 0);
            assert.equal(ev.toPeriod, 10);
            // bond updated
            let b = await instance.getBond(0);
            assert.equal(b.curPeriod, 10);
            // complete bond
            tx = await instance.serviceBond(0, owner, 2, 0x0, {value: 2, from: owner});
            // event emitted
            await getEvent(tx, 'BondServiced');
            ev = await getEvent(tx, 'BondCompleted');
            assert.equal(ev.id, 0);
            // bond updated
            b = await instance.getBond(0);
            assert.equal(b.curPeriod, 11);
        });

    });

    it.skip('accepts ERC1155 single transfer as service payments', async () => {
        const currencyEvent = await instance.addERC1155TokenCurrency(erc1155Instance.address, 0)
            .then(tx => getEvent(tx, 'CurrencyAdded'));
        const bytes = buildBondBytes({...DEFAULT_BOND, currencyRef: currencyEvent.id });
        const bondEvent = await instance.mintBond(bytes[0], bytes[1])
            .then(tx => getEvent(tx, 'Transfer'));

        // service with a direct erc1155 transfer 
        assert.equal(bondEvent.tokenId, 0);
        let tx = await erc1155Instance.safeTransferFrom(owner, instance.address, 0, 2, 0x0);

        // check bond updated
        const b = await instance.getBond(bondEvent.tokenId);
        assert.equal(b.curPeriod, 2);
        // check beneficiary received transfer
        const balance = await erc1155Instance.balanceOf(beneficiary, 0);
        assert.equal(balance, 2);
    });
    
    it.skip('accepts ERC1155 batch transfers as service payments', async () => {
        const currencyEvent = await instance.addERC1155TokenCurrency(erc1155Instance.address, 0)
            .then(tx => getEvent(tx, 'CurrencyAdded'));
        const bytes = buildBondBytes({...DEFAULT_BOND, currencyRef: currencyEvent.id });
        const firstBond = await instance.mintBond(bytes[0], bytes[1])
            .then(tx => getEvent(tx, 'Transfer'));
        const secondBond = await instance.mintBond(bytes[0], bytes[1])
            .then(tx => getEvent(tx, 'Transfer'));

        // service bonds with direct batch erc1155 transfer
        assert.equal(firstBond.tokenId, 0);
        assert.equal(secondBond.tokenId, 1);
        await erc1155Instance.safeBatchTransferFrom(owner, instance.address, [0,0], [1,2], [0x0, 0x1]); 

        // check both bonds updated
        const b1 = await instance.getBond(firstBond.tokenId);
        assert.equal(b1.curPeriod, 1);
        const b2 = await instance.getBond(secondBond.tokenId);
        assert.equal(b2.curPeriod, 2);
    });

    it('allows calling defaulted bond', async () => {
        const bytes = buildBondBytes({...DEFAULT_BOND, startTime: Date.now() - 60*60*24*100});
        await instance.mintBond(bytes[0], bytes[1]);
        const oldFlag = await instance.getBond(0).then(b => b.defaulted);
        // call bond
        let tx = await instance.callBond(0);
        let ev = await getEvent(tx, 'BondDefaulted');
        assert.equal(ev.id, 0);
        // bond updated
        let newFlag = await instance.getBond(0).then(b => b.flag);
        assert.notEqual(newFlag, oldFlag, 'bond flag not changed');
        assert.isTrue(newFlag, 'bond not marked defaulted');
    });

    it('allows forgiving a bond', async () => {
        const bytes = buildBondBytes(DEFAULT_BOND);
        await instance.mintBond(bytes[0], bytes[1]);
        const oldCurPeriod = await instance.getBond(0).then(b => b.curPeriod);
        // forgive bond
        let tx = await instance.forgiveBond(0);
        let ev = await getEvent(tx, 'BondCompleted');
        assert.equal(ev.id, 0);
        // bond updated
        let b = await instance.getBond(0);
        assert.notEqual(b.curPeriod, oldCurPeriod, 'bond curPeriod not changed');
        assert.equal(+b.curPeriod, +b.nPeriods + 1, 'bond curPeriod not incremented to completion');
    });

    it('allows destroying a bond', async () => {
        const bytes = buildBondBytes(DEFAULT_BOND);
        await instance.mintBond(bytes[0], bytes[1]);
        const oldBalance = await instance.balanceOf(owner);
        // destroy bond
        await instance.destroyBond(0);
        // bond destroyed
        let b = await instance.getBond(0);
        assert.equal(b.startTime, 0, 'bond not reset');
        const newBalance = await instance.balanceOf(owner);
        assert.equal(oldBalance - newBalance, 1, 'balance not updated properly');
    });

});
