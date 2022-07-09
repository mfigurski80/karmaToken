<template>
  <button v-if="!connected" @click="connect">Connect Wallet</button>
  <div v-if="connected" v-for="c in contractData" :key="c.name">
    <ContractInteraction :contract="c" :web3="web3"/>
  </div>
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
    contractData: [{
      name: 'CollateralManager',
      address: '0xDD5D7Bd43be613c21645E07d64a9e89cf59CaE55',
      abiPath: '/contracts/CollateralManager.json',
    }],
  }),
  methods: {
    async connect() {
        if (!window.ethereum) {
          alert('Please install metamask or another web3 provider');
          return;
        }
        await window.ethereum.request({method: 'eth_requestAccounts'});
        this.web3 = new Web3(window.ethereum);
        this.connected = true;
    },
  },
}
</script>

