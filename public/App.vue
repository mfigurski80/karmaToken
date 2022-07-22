<template>
  <button v-if="!connected" @click="connect">Connect Wallet</button>
  <div v-if="connected"
    v-for="c in contractData" :key="c.name"
  >
    <ContractInteraction
      :contract="c"
      :web3="web3"
      :accounts="accounts"
    />
  </div>
  <p v-if="connected & contractData.length === 0">
    This network does not have supported contracts.
  </p>
</template>

<script>
import ContractInteraction from './ContractInteraction.vue';

export default {
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
      let data = await fetch('addresses.txt')
        .then(res => res.text())
      this.contractData = [...((data + "\n\n").matchAll(regex))]
        .filter(m => +m[1] === +window.ethereum.networkVersion)
        .map(m => m[2].trim().split('\n  '))
        .flat()
        .map(cData => cData.split(': '))
        .filter(cArr => c[0] !== "No contracts deployed.");
        .map(cArr => ({
          name: cArr[0],
          address: cArr[1],
          abiPath: `contracts/${cArr[0]}.json`,
        })); 
    }, 
  },
}
</script>

