module.exports = async function(callback) {
   web3.eth.sendTransaction({from: (await web3.eth.getAccounts())[0], to: '0x2e7098b8eA74ed30dDF3d239f794385002dd3Ffe', value: web3.utils.toWei('2', 'ether')});
  callback();
}
