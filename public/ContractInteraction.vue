<template>
  <h3>{{contract.name}} Contract deployed at: 
    <code>{{ contract.address }}</code>
  </h3>
  <h6>Status: {{connected ? 'Connected' : 'Disconnected'}}</h6>
  <div v-for="f in fields" :key="f.id">

    <form @submit.prevent="performMethod(f.id)">
      <hr />
      <h4>Function: <code>{{f.name}}</code></h4>
      <p>{{f.notice}}</p>
      <p>{{f.details}}</p>
      <label v-if="f.payable">Wei to send: <input placeholder="10000"
        v-model.number="f.payableValue"
      /></label>
      <div v-for="i in f.inputs">

        <label> Parameter: {{i.name}} {{i.type}} -- {{i.description}} <input
          v-model='i.value'
          :placeholder="placeholders[i.type]"
        /></label> 

      </div>
      <button type="submit">Call Method</button>
    </form>

  </div>
</template>

<script>
export default {
  name: 'ContractInteraction',
  props: ["contract", "web3"],
  data: () => ({
    connected: false,
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
    if (!this.web3) alert('ERR: interaction without web3 connection!');
    const cJ = await fetch(this.contract.abiPath)
      .then(res => res.json());
    this.obj = new this.web3.eth.Contract(cJ.abi, this.contract.address);
    this.connected = true;
    this.fields = this.parseMethods(cJ);
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
    async performMethod(id) {
      // user submitted data for specific method to be performed
      console.log(id);
      console.log(this.fields[id]);
    },
  },
}
</script>
