const ERC721 = artifacts.require('ERC721');

contract('ERC721', (accounts) => {
    let instance;
    const args = {name: 'Test Token', symbol: 'TST', uri: 'http://localhost'};

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
        let balance = await instance.balanceOf(accounts[0]);
        assert.equal(balance, 0);
    }); 

});