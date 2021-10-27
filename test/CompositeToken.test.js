const CompositeToken = artifacts.require('CompositeTokenExposed');

const { getEvent, getEvents, getRevert } = require('./utils');

contract('CompositeToken', (accounts) => {
    let instance;
    let receiverInstance;
    const owner = accounts[0];
    const receiver = accounts[1];
    const operator = accounts[2];
    const ID = 0;
    const ID2 = 1;
    const ID3 = 2;
    const args = { name: 'Test Token', symbol: 'TST', uri: 'http://localhost' };


    beforeEach(async () => {
        instance = await CompositeToken.new(args.name, args.symbol, args.uri);
    });

    it('exposes name and symbol', async () => {
        const name = await instance.name();
        assert.equal(name, args.name);
        const symbol = await instance.symbol();
        assert.equal(symbol, args.symbol);
    });

    it('exposes constant uri', async () => {
        let uri = await instance.uri(0);
        assert.notEqual(uri, '');
        let check = await instance.uri(1);
        assert.equal(uri, check);
    });

    it('supports ERC721 and ERC1155 interface', async () => {
        let supportsInterface = await instance.supportsInterface('0x80ac58cd');
        assert.isTrue(supportsInterface, 'returns true on ERC721 interface');
        supportsInterface = await instance.supportsInterface('0xd9b67a26');
        assert.isTrue(supportsInterface, 'returns true on ERC1155 interface');
    });

    it('allows checking and batch checking balance', async () => {
        let balance = await instance.balanceOf(owner, ID);
        assert.equal(balance, 0);
        let balances = await instance.balanceOfBatch([owner, receiver], [ID, ID]);
        assert.equal(balances[0], 0);
        assert.equal(balances[1], 0);
    });

    it('allows checking token owner (ERC721)', async () => {
        let newOwner = await instance.ownerOf(ID);
        assert.equal(newOwner, 0x0);
    });

    it('allows checking token owner by batch', async () => {
        let newOwners = await instance.ownerOfBatch([ID, ID2]);
        assert.equal(newOwners[0], 0x0);
        assert.equal(newOwners[1], 0x0);
    })

    it('allows minting tokens (exposed version)', async () => {
        await instance.mint(owner, ID);
        let balance = await instance.balanceOf(owner, ID);
        assert.equal(balance, 1);

        await instance.mint(owner, ID2);
        balance = await instance.balanceOf(owner, ID2);
        assert.equal(balance, 1);
    });

    it('allows batch minting tokens (exposed version)', async () => {
        await instance.mintBatch(owner, [ID, ID2]);
        let balances = await instance.balanceOfBatch([owner, owner], [ID, ID2]);
        assert.equal(balances[0], 1);
        assert.equal(balances[1], 1);
    });

    it('emits all ERC721 events when minting', async () => {
        let tx = await instance.mint(owner, ID);
        let ev = await getEvent(tx, 'Transfer');
        assert.equal(ev.from, 0x0);
        assert.equal(ev.to, owner);
        assert.equal(ev.tokenId, ID);
        
        tx = await instance.mintBatch(owner, [ID2, ID3]);
        let evs = await getEvents(tx, 'Transfer');
        assert.equal(evs.length, 2, 'Transfer emitted for each item in batch');
        assert.equal(evs[0].tokenId, ID2);
        assert.equal(evs[1].tokenId, ID3);
    });

    it('emits all ERC1155 events when minting', async () => {
        let tx = await instance.mint(owner, ID);
        let ev = await getEvent(tx, 'TransferSingle');
        assert.equal(ev.operator, owner);
        assert.equal(ev.from, 0x0);
        assert.equal(ev.to, owner);
        assert.equal(ev.id, ID);
        assert.equal(ev.value, 1);

        tx = await instance.mintBatch(owner, [ID2, ID3]);
        ev = await getEvent(tx, 'TransferBatch');
        assert.equal(ev.operator, owner);
        assert.equal(ev.from, 0x0);
        assert.equal(ev.to, owner);
        assert.equal(ev.ids.length, 2);
        assert.equal(ev.ids[0], ID2);
        assert.equal(ev.ids[1], ID3);
        assert.equal(ev.values.length, 2);
        assert.equal(ev.values[0], 1);
        assert.equal(ev.values[1], 1);
    });

    it('allows safe transfer and safe batch transfer of tokens', async () => {
        await instance.mintBatch(owner, [ID, ID2, ID3]);
        await instance.safeTransferFrom(owner, receiver, ID, 1, 0x0);
        let balance = await instance.balanceOf(owner, ID);
        assert.equal(balance, 0);
        let receiverBalance = await instance.balanceOf(receiver, ID);
        assert.equal(receiverBalance, 1);
        let newOwner = await instance.ownerOf(ID);
        assert.equal(newOwner, receiver);

        await instance.safeBatchTransferFrom(owner, receiver, [ID2, ID3], [1,1], 0x0);
        balance = await instance.balanceOfBatch([owner, owner], [ID2, ID3]);
        assert.equal(balance[0], 0);
        assert.equal(balance[1], 0);
        receiverBalance = await instance.balanceOfBatch([receiver, receiver], [ID2, ID3]);
        assert.equal(receiverBalance[0], 1, 'first token not received');
        assert.equal(receiverBalance[1], 1, 'second token not received');
        newOwner = await instance.ownerOfBatch([ID2, ID3]);
        assert.equal(newOwner[0], receiver);
        assert.equal(newOwner[1], receiver);
    });

});