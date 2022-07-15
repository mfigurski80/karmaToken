
import ContractInteraction from './ContractInteraction.vue.js';

const defaultExport = {
  name: 'App',
  components: {
    ContractInteraction,
  },
  data: () => ({
    connected: false,
    web3: null,
    accounts: [],
    contractData: [],
  }),
  methods: {
    async connect() {
      if (!window.ethereum) {
        alert('Please install metamask or another web3 provider');
        return;
      }
      // get accounts
      this.accounts = await window.ethereum.request(
        { method: 'eth_requestAccounts' });
      window.ethereum.on('accountsChanged',
        accs => this.accounts = accs);
      // build web3 obj
      this.web3 = new Web3(window.ethereum);
      // read contracts we can expect
      /* this.contractData =  */
      await this.fetchContractData();
      this.connected = true;
    },
    async fetchContractData() {
      // Pattern: https://regexr.com/6ph9t
      const regex = /Network: \w* \(id: (\d*)\)([\s\S]*?)(?=\n{2,})/gm;
      let data = await fetch('/addresses.txt')
        .then(res => res.text())
      this.contractData = [...((data + "\n\n").matchAll(regex))]
        .filter(m => +m[1] === +window.ethereum.networkVersion)
        .map(m => m[2].trim().split('\n  ')).flat()
        .map(cData => cData.split(': '))
        .map(cArr => ({
          name: cArr[0],
          address: cArr[1],
          abiPath: `/contracts/${cArr[0]}.json`,
        })); 
    }, 
  },
}

import { openBlock as _openBlock, createElementBlock as _createElementBlock, createCommentVNode as _createCommentVNode, renderList as _renderList, Fragment as _Fragment, resolveComponent as _resolveComponent, createVNode as _createVNode } from "./_snowpack/pkg/vue.js"

const _hoisted_1 = { key: 2 }

export function render(_ctx, _cache) {
  const _component_ContractInteraction = _resolveComponent("ContractInteraction")

  return (_openBlock(), _createElementBlock(_Fragment, null, [
    (!_ctx.connected)
      ? (_openBlock(), _createElementBlock("button", {
          key: 0,
          onClick: _cache[0] || (_cache[0] = (...args) => (_ctx.connect && _ctx.connect(...args)))
        }, "Connect Wallet"))
      : _createCommentVNode("", true),
    (_ctx.connected)
      ? (_openBlock(true), _createElementBlock(_Fragment, { key: 1 }, _renderList(_ctx.contractData, (c) => {
          return (_openBlock(), _createElementBlock("div", {
            key: c.name
          }, [
            _createVNode(_component_ContractInteraction, {
              contract: c,
              web3: _ctx.web3,
              accounts: _ctx.accounts
            }, null, 8, ["contract", "web3", "accounts"])
          ]))
        }), 128))
      : _createCommentVNode("", true),
    (_ctx.connected & _ctx.contractData.length === 0)
      ? (_openBlock(), _createElementBlock("p", _hoisted_1, " This network does not have supported contracts. "))
      : _createCommentVNode("", true)
  ], 64))
};

defaultExport.render = render;

export default defaultExport;