const ERC721 = artifacts.require('ERC721Exposed');
const ERC721ReceiverExposed = artifacts.require('ERC721ReceiverExposed');

const { getEvent, getRevert } = require('./utils');


contract('ERC721', (accounts) => {
    let instance;
    let receiverInstance;
    const owner = accounts[0];
    const operator = accounts[1];
    const receiver = accounts[2];
    const ID = 0;
    const args = { name: 'Test Token', symbol: 'TST', uri: 'http://localhost' };

    before(async () => {
        receiverInstance = await ERC721ReceiverExposed.new();
    });

    beforeEach(async () => {
        instance = await ERC721.new(args.name, args.symbol, args.uri);
    });

    it('deploys successfully', async () => {
        assert.ok(instance);
    });

    it('it exposes name and symbol', async () => {
        let name = await instance.name();
        assert.equal(name, args.name);
        let symbol = await instance.symbol();
        assert.equal(symbol, args.symbol);
    });

    it('exposes a constant token uri', async () => {
        let uri = await instance.tokenURI(0);
        assert.notEqual(uri, '');
        let check = await instance.tokenURI(1);
        assert.equal(uri, check);
    });

    it('supports ERC721 interface', async () => {
        let supportsInterface = await instance.supportsInterface('0x80ac58cd');
        assert.equal(supportsInterface, true);   
    });

    it('initializes with a balance of zero', async () => {
        let balance = await instance.balanceOf(owner);
        assert.equal(balance, 0);
    });

    it('allows minting of tokens (exposed version)', async () => {
        const ID = 0;
        let tx = await instance.mint(owner, ID);
        let ev = await getEvent(tx, 'Transfer');
        assert.equal(ev.from, 0x0);
        assert.equal(ev.to, owner);
        assert.equal(ev.tokenId, ID);

        let balance = await instance.balanceOf(owner);
        assert.equal(balance, 1, 'balance has been increased');
        let newOwner = await instance.ownerOf(ID);
        assert.equal(newOwner, owner, 'new owner has been set');
    });

    it('allows transfering tokens', async () => {
        const ID = 0;
        await instance.mint(owner, ID);
        let tx = await instance.transferFrom(owner, receiver, ID);
        let ev = await getEvent(tx, 'Transfer');
        assert.equal(ev.from, owner);
        assert.equal(ev.to, receiver);
        assert.equal(ev.tokenId, ID);

        let balance = await instance.balanceOf(owner);
        assert.equal(balance, 0, 'balance has been decreased');
        let receiverBalance = await instance.balanceOf(receiver);
        assert.equal(receiverBalance, 1, 'receiver balance has been increased');
        let newOwner = await instance.ownerOf(ID);
        assert.equal(newOwner, receiver, 'new owner has been set');
    });

    it('dissallows transfers by invalid operators', async () => {
        await instance.mint(owner, ID);
        let err = await getRevert(instance.transferFrom(owner, receiver, ID, {from: receiver}));
        assert.include(err.message.toLowerCase(), 'owner');
    });

    it('dissallows transfers of invalid tokens', async () => {
        let err = await getRevert(instance.transferFrom(owner, receiver, ID));
        assert.include(err.message.toLowerCase(), 'transfer');
    });

    it('allows operator token approvals', async () => {
        await instance.mint(owner, ID);
        let tx = await instance.approve(operator, ID);
        let ev = await getEvent(tx, 'Approval');
        assert.equal(ev.owner, owner);
        assert.equal(ev.approved, operator);
        assert.equal(ev.tokenId, ID);

        let approved = await instance.getApproved(ID);
        assert.equal(approved, operator);

        tx = await instance.transferFrom(owner, operator, ID, {from: operator});
        ev = await getEvent(tx, 'Transfer');
        assert.equal(ev.from, owner);
        assert.equal(ev.to, operator);
        assert.equal(ev.tokenId, ID);
    });

    it('allows operator full approvals', async () => {
        await instance.mint(owner, ID);
        let tx = await instance.setApprovalForAll(operator, true);
        let ev = await getEvent(tx, 'ApprovalForAll');
        assert.equal(ev.owner, owner);
        assert.equal(ev.operator, operator);
        assert.equal(ev.approved, true);

        let approved = await instance.isApprovedForAll(owner, operator);
        assert.equal(approved, true);

        tx = await instance.transferFrom(owner, operator, ID, {from: operator});
        ev = await getEvent(tx, 'Transfer');
        assert.equal(ev.from, owner);
        assert.equal(ev.to, operator);
        assert.equal(ev.tokenId, ID);
    });

    it('dissallows safe transfers to non ERC721Receiver contract', async () => {
        await instance.mint(owner, ID);
        let err = await getRevert(instance.safeTransferFrom(owner, instance.address, ID));
        assert.include(err.message.toLowerCase(), 'receiver');
    });

    it('allows safe transfer to ERC721Receiver contact', async () => {
        await instance.mint(owner, ID);
        let tx = await instance.safeTransferFrom(owner, receiverInstance.address, ID);
        let ev = await getEvent(tx, 'Transfer');
        assert.equal(ev.from, owner);
        assert.equal(ev.to, receiverInstance.address);
        assert.equal(ev.tokenId, ID);
    });

    it('reverts when ERC721Receiver rejects tokens', async () => {
        await instance.mint(owner, ID);
        let err = await getRevert(instance.safeTransferFrom(owner, receiverInstance.address, ID, '0xFF'));
        assert.include(err.message.toLowerCase(), 'reject');
    });

});