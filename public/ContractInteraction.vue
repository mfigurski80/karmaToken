<template>
  <hr />
  <h2>{{contract.name}} Contract at: 
    <code>{{ contract.address }}</code>
  </h2>
  <button @click="toggleHidden">{{hidden ? 'Show' : 'Hide'}} Methods</button>
  <h6>Status: {{connected ? 'Connected' : 'Disconnected'}}</h6>
  <form v-if="!hidden" v-for="f in fields" :key="f.id" 
    @submit.prevent="handleDoMethod(f.id)"
  >
    <hr />
    <h4>Function: <code>{{f.name}}</code></h4>
    <p>{{f.notice}}</p>
    <p>{{f.details}}</p>
    <label v-if="f.payable">Wei to send: <input placeholder="10000"
      v-model.number="f.payableValue"
    /></label>
    <div v-for="i in f.inputs">

      <label>Parameter <b>{{i.name}}</b> ({{i.type}}) -- {{i.description}}<input
        v-model='i.value'
        :placeholder="placeholders[i.type]"
      /></label> 

    </div>
    <button type="submit">Call Method</button>
    <p v-if="f.response">Last Response: {{f.response}}</p>
  </form>
</template>

<script>
export default {
  name: 'ContractInteraction',
  props: ["contract", "web3", "accounts"],
  data: () => ({
    connected: false,
    hidden: true,
    obj: null,
    fields: [],
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
    let resp = await this.web3.eth.getCode(this.contract.address);
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
      /* console.log(Object.keys(this.obj.events).filter((_, i) => i % 3 === 0)); */
      this.obj.events.allEvents({})
        .on('connected', () => this.connected = true)
        .on('data', ev => {
          console.log('Event:', ev);
          alert('New Event');
        });
    },
    toggleHidden() {
      this.hidden = !this.hidden;
    },
    async handleDoMethod(id) {
      // user submitted data for specific method to be performed
      const m = this.fields[id];
      const inp = m.inputs.map(inp => inp.value);
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
      console.log('Response: ', res);
    },
  },
}
</script>
