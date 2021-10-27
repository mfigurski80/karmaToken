const SuperERC721 = artifacts.require('SuperERC721Exposed');
const ERC721ReceiverExposed = artifacts.require('ERC721ReceiverExposed');

const { getEvent, getEvents, getRevert } = require('./utils');

contract('SuperERC721', accounts => {
    let instance;
    let receiverInstance;
    const owner = accounts[0];
    const receiver = accounts[1];
    const operator = accounts[2];
    const ID = 0;
    const ID2 = 1;
    const ID3 = 2;
    const args = { name: 'Test Token', symbol: 'TST', uri: 'http://localhost' };

    before(async () => {
        receiverInstance = await ERC721ReceiverExposed.new();
    });

    beforeEach(async () => {
        instance = await SuperERC721.new(args.name, args.symbol, args.uri);
    });

    it('deploys successfully', async () => {
        assert.ok(instance);
    });

    it('allows getting batch balance', async () => {
        const balance = await instance.balanceOfBatch([owner, receiver]);
        assert.equal(balance[0].toNumber(), 0);
        assert.equal(balance[1].toNumber(), 0);
    });

    it('allows getting owners of ids batch', async () => {
        await instance.mint(owner, ID);
        const owners = await instance.ownerOfBatch([ID, ID2]);
        assert.equal(owners[0], owner);
        assert.equal(owners[1], 0x0);
    });

    it('allows setting batch approval for all', async () => {
        await instance.setBatchApprovalForAll([operator, receiver], true);
        let approved = await instance.isApprovedForAll(owner, operator);
        assert.isTrue(approved);
        approved = await instance.isApprovedForAll(owner, receiver);
        assert.isTrue(approved);
    });

    it('emits multiple events when setting batch approval', async () => {
        let tx = await instance.setBatchApprovalForAll([operator, receiver], true);
        let evs = await getEvents(tx, 'ApprovalForAll');
        assert.equal(evs.length, 2);
    })

    it('allows batch minting', async () => {
        await instance.mintBatch(owner, [ID, ID2]);
        const balance = await instance.balanceOf(owner);
        assert.equal(balance.toNumber(), 2);
        let owners = await instance.ownerOfBatch([ID, ID2]);
        assert.equal(owners[0], owner);
        assert.equal(owners[1], owner);
    });

    it('emits multiple events when batch minting', async () => {
        let tx = await instance.mintBatch(owner, [ID, ID2]);
        let evs = await getEvents(tx, 'Transfer');
        assert.equal(evs.length, 2);
    });

    it('allows batch transfers', async () => {
        await instance.mintBatch(owner, [ID, ID2]);
        await instance.safeBatchTransferFrom(owner, receiver, [ID, ID2], 0x0);
        const balances = await instance.balanceOfBatch([owner, receiver]);
        assert.equal(balances[0].toNumber(), 0);
        assert.equal(balances[1].toNumber(), 2);
        const owners = await instance.ownerOfBatch([ID, ID2]);
        assert.equal(owners[0], receiver);
        assert.equal(owners[1], receiver);
    });

    it('emits multiple events during batch transfers', async () => {
        await instance.mintBatch(owner, [ID, ID2]);
        let tx = await instance.safeBatchTransferFrom(owner, receiver, [ID, ID2], 0x0);
        let evs = await getEvents(tx, 'Transfer');
        assert.equal(evs.length, 2);
    });

    it('respects operators when batch transferring', async () => {
        await instance.mintBatch(owner, [ID, ID2]);
        await instance.setApprovalForAll(operator, true);
        await instance.safeBatchTransferFrom(owner, receiver, [ID, ID2], 0x0, { from: operator });

        let err = await getRevert(instance.safeBatchTransferFrom(receiver, owner, [ID, ID2], 0x0));
        assert.include(err.message.toLowerCase(), 'operator');
    });

    it('checks for ERC721Receiver when batch transferring', async () => {
        await instance.mintBatch(owner, [ID, ID2]);
        let err = await getRevert(instance.safeBatchTransferFrom(owner, instance.address, [ID, ID2], 0x0));
        assert.include(err.message.toLowerCase(), 'erc721receiver');

        instance.safeBatchTransferFrom(owner, receiverInstance.address, [ID, ID2], 0x0);
    });

})