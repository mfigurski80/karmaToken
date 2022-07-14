<template>
  <hr />
  <h2>{{contract.name}} Contract at: 
    <code>{{ contract.address }}</code>
  </h2>
  <button v-if="connected" @click="toggleHidden">{{hidden ? 'Show' : 'Hide'}} Methods</button>
  <h6>Status: {{connected ? 'Connected' : 'Disconnected'}}</h6>
  <div v-if="events.length > 0">
    <h4>Events emitted by this contract</h4>
    <p v-for="e in events" :key={e}>{{e.event}}: ({{e.data}})</p>
  </div>
  <div v-if="!hidden || !connected">
    <form 
      v-for="f in fields" :key="f.id" 
      @submit.prevent="handleDoMethod(f.id)"
    >
      <hr :style="{ borderStyle: 'dotted' }" />
      <h4>Function: <code>{{f.name}}</code></h4>
      <p>{{f.notice}}</p>
      <p>{{f.details}}</p>
      <label v-if="f.payable">Wei to send: <input placeholder="10000"
        v-model.number="f.payableValue"
      /></label>
      <div v-for="i in f.inputs" :key="i.name">

        <label>Parameter <b>{{i.name}}</b> ({{i.type}}) -- {{i.description}} <input
          v-model='i.value'
          :placeholder="placeholders[i.type]"
        /></label> 

      </div>
      <button type="submit">Call Method</button>
      <p v-if="f.response">Last Response: {{f.response}}</p>
    </form>
  </div>
</template>

<script>
import * as utils from './utils.js';

export default {
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
      console.log(`${this.contract.name}: Connecting Events`);
      this.obj.events.allEvents({})
        .on('connected', () => this.connected = true)
        .on('data', ev => {
          console.log(`${ev.event} Event: `, ev);
          alert(`New ${ev.event} Event!`);
          this.events.push({
            event: ev.event,
            data: utils.removeNumberKeys(ev.returnValues),
          });
        });
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
      console.log('Response: ', res);
    },
  },
}
</script>
