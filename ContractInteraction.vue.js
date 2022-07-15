
import * as utils from './utils.js';

const defaultExport = {
  name: 'ContractInteraction',
  props: ["contract", "web3", "accounts"],
  data: () => ({
    connected: false,
    hidden: true,
    obj: null,
    fields: [],
    events: [],
    placeholders: {
      'uint256': '100',
      'uint256[]': '[100, 101]',
      'address': '0xDD5D7Bd43be613c21645E07d64a9e89cf59CaE55',
      'address[]': '[0xDD5D7Bd43be613c21645E07d64a9e89cf59CaE55]',
      'bytes32': '0x0000000000000000000000000000000000000000000000000000000000000000',
      'bytes4': '0x00000000',
      'bool': 'true',
    },
  }),
  async mounted() {
    if (!this.web3) { 
      alert('ERR: Interaction without web3 connection!');
      return;
    }
    let resp = await this.web3.eth.getCode(this.contract.address)
      .catch(err => { alert(err); return '0x'; });
    if (resp === '0x') {
      alert(`ERR: No contract found at ${this.contract.address} (${this.contract.name})`);
      return;
    }

    const cJ = await fetch(this.contract.abiPath)
      .then(res => res.json());
    this.obj = new this.web3.eth.Contract(cJ.abi, this.contract.address);
    /* this.connected = true; */
    this.fields = this.parseMethods(cJ);
    this.connectEvents(cJ);
  },
  methods: {
    parseMethods(cJ) {
      const userDoc = Object.fromEntries(Object.keys(cJ.userdoc.methods)
        .map(fnSig => [fnSig.split('(')[0], cJ.userdoc.methods[fnSig].notice]
      ));
      const devDoc = Object.fromEntries(Object.keys(cJ.devdoc.methods)
        .map(fnSig => [fnSig.split('(')[0], cJ.devdoc.methods[fnSig]]
      ));
      return cJ.abi.filter(el => el.type === 'function')
        .map((fn,i) => ({
          ...fn, 
          id: i,
          notice: userDoc[fn.name],
          details: devDoc[fn.name]?.details,
          inputs: fn.inputs.map(inp => ({
            ...inp,
            description: devDoc[fn.name]?.params?.[inp.name],
          })),
        }));
    },
    connectEvents(cJ) {
      this.connected=true;
      /* console.log(`${this.contract.name}: Connecting Events`); */
      /* this.obj.events.allEvents({}) */
      /* .on('connected', () => this.connected = true) */
      /* .on('data', ev => { */
      /* console.log(`${ev.event} Event: `, ev); */
      /* alert(`New ${ev.event} Event!`); */
      /* this.events.push({ */
      /* event: ev.event, */
      /* data: utils.removeNumberKeys(ev.returnValues), */
      /* }); */
      /* };); */
    },
    toggleHidden() {
      this.hidden = !this.hidden;
    },
    async handleDoMethod(id) {
      // user submitted data for specific method to be performed
      const m = this.fields[id];
      // call a formatting function unless type is not recognized
      const formattingFns = ({
        'bool': v => v === 'true' || v === 'True',
        'uint': v => Math.abs(+v),
        'int': v => +v,
      });
      const inp = m.inputs
        .map(inp => 
          (formattingFns[inp.type.replace(/\d/g, '')] || (v => v))(inp.value));
      // decide whether to send or call request
      let prom = this.obj.methods[m.name](...inp);
      if (m.constant) { // just inspect data
        console.log(`Calling ${m.name}(${inp})`);
        prom = prom.call();
      } else { // perform actual action to change state 
        console.log(`Sending ${m.name}(${inp}) from ${this.accounts[0]}`);
        prom = prom.send({from: this.accounts[0], value: m.payableValue || 0});
      };
      // run and get result
      const res = await prom.catch(err => {
        alert(`ERR: ${err.message}`);
        console.error(err);
        return;
      });
      m.response = res;
      if (typeof res === 'object') m.response = utils.removeNumberKeys(res);
      this.events = this.events.concat(res.events ? Object.keys(res.events)
        .map(evKey => ({
          event: res.events[evKey].event,
          data: utils.removeNumberKeys(res.events[evKey].returnValues),
        })) : []
      );
      console.log('Response: ', res);
    },
  },
}

import { createElementVNode as _createElementVNode, toDisplayString as _toDisplayString, createTextVNode as _createTextVNode, openBlock as _openBlock, createElementBlock as _createElementBlock, createCommentVNode as _createCommentVNode, renderList as _renderList, Fragment as _Fragment, vModelText as _vModelText, withDirectives as _withDirectives, withModifiers as _withModifiers } from "./_snowpack/pkg/vue.js"

const _hoisted_1 = /*#__PURE__*/_createElementVNode("hr", null, null, -1)
const _hoisted_2 = { key: 1 }
const _hoisted_3 = /*#__PURE__*/_createElementVNode("h4", null, "Events emitted by Your Transactions", -1)
const _hoisted_4 = { key: 2 }
const _hoisted_5 = ["onSubmit"]
const _hoisted_6 = /*#__PURE__*/_createElementVNode("hr", { style: { borderStyle: 'dotted' } }, null, -1)
const _hoisted_7 = /*#__PURE__*/_createTextVNode("Function: ")
const _hoisted_8 = { key: 0 }
const _hoisted_9 = /*#__PURE__*/_createTextVNode("Wei to send: ")
const _hoisted_10 = ["onUpdate:modelValue"]
const _hoisted_11 = /*#__PURE__*/_createTextVNode("Parameter ")
const _hoisted_12 = ["onUpdate:modelValue", "placeholder"]
const _hoisted_13 = /*#__PURE__*/_createElementVNode("button", { type: "submit" }, "Call Method", -1)
const _hoisted_14 = { key: 1 }

export function render(_ctx, _cache) {
  return (_openBlock(), _createElementBlock(_Fragment, null, [
    _hoisted_1,
    _createElementVNode("h2", null, [
      _createTextVNode(_toDisplayString(_ctx.contract.name) + " Contract at: ", 1),
      _createElementVNode("code", null, _toDisplayString(_ctx.contract.address), 1)
    ]),
    (_ctx.connected)
      ? (_openBlock(), _createElementBlock("button", {
          key: 0,
          onClick: _cache[0] || (_cache[0] = (...args) => (_ctx.toggleHidden && _ctx.toggleHidden(...args)))
        }, _toDisplayString(_ctx.hidden ? 'Show' : 'Hide') + " Methods", 1))
      : _createCommentVNode("", true),
    _createElementVNode("h6", null, "Status: " + _toDisplayString(_ctx.connected ? 'Connected' : 'Disconnected'), 1),
    (_ctx.events.length > 0)
      ? (_openBlock(), _createElementBlock("div", _hoisted_2, [
          _hoisted_3,
          (_openBlock(true), _createElementBlock(_Fragment, null, _renderList(_ctx.events, (e) => {
            return (_openBlock(), _createElementBlock("p", {
              key: {e}
            }, _toDisplayString(e.event) + ": (" + _toDisplayString(e.data) + ")", 1))
          }), 128))
        ]))
      : _createCommentVNode("", true),
    (!_ctx.hidden || !_ctx.connected)
      ? (_openBlock(), _createElementBlock("div", _hoisted_4, [
          (_openBlock(true), _createElementBlock(_Fragment, null, _renderList(_ctx.fields, (f) => {
            return (_openBlock(), _createElementBlock("form", {
              key: f.id,
              onSubmit: _withModifiers($event => (_ctx.handleDoMethod(f.id)), ["prevent"])
            }, [
              _hoisted_6,
              _createElementVNode("h4", null, [
                _hoisted_7,
                _createElementVNode("code", null, _toDisplayString(f.name), 1)
              ]),
              _createElementVNode("p", null, _toDisplayString(f.notice), 1),
              _createElementVNode("p", null, _toDisplayString(f.details), 1),
              (f.payable)
                ? (_openBlock(), _createElementBlock("label", _hoisted_8, [
                    _hoisted_9,
                    _withDirectives(_createElementVNode("input", {
                      placeholder: "10000",
                      "onUpdate:modelValue": $event => ((f.payableValue) = $event)
                    }, null, 8, _hoisted_10), [
                      [
                        _vModelText,
                        f.payableValue,
                        void 0,
                        { number: true }
                      ]
                    ])
                  ]))
                : _createCommentVNode("", true),
              (_openBlock(true), _createElementBlock(_Fragment, null, _renderList(f.inputs, (i) => {
                return (_openBlock(), _createElementBlock("div", {
                  key: i.name
                }, [
                  _createElementVNode("label", null, [
                    _hoisted_11,
                    _createElementVNode("b", null, _toDisplayString(i.name), 1),
                    _createTextVNode(" (" + _toDisplayString(i.type) + ") -- " + _toDisplayString(i.description) + " ", 1),
                    _withDirectives(_createElementVNode("input", {
                      "onUpdate:modelValue": $event => ((i.value) = $event),
                      placeholder: _ctx.placeholders[i.type]
                    }, null, 8, _hoisted_12), [
                      [_vModelText, i.value]
                    ])
                  ])
                ]))
              }), 128)),
              _hoisted_13,
              (f.response)
                ? (_openBlock(), _createElementBlock("p", _hoisted_14, "Last Response: " + _toDisplayString(f.response), 1))
                : _createCommentVNode("", true)
            ], 40, _hoisted_5))
          }), 128))
        ]))
      : _createCommentVNode("", true)
  ], 64))
};

defaultExport.render = render;

export default defaultExport;