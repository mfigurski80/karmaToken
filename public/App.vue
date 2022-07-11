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
    contractData: [{
      name: 'CollateralManager',
      address: '0xB70C08Cf5Afc879432A707c9efC2011c26021b47',
      abiPath: '/contracts/CollateralManager.json',
    }, {
      name: 'ERC20Exposed',
      address: '0x7d38fa09c75aE4bD196Bd8608eFd4f95Ff734896',
      abiPath: '/contracts/ERC20Exposed.json',
    }],
  }),
  methods: {
    async connect() {
        if (!window.ethereum) {
          alert('Please install metamask or another web3 provider');
          return;
        }
        this.accounts = await window.ethereum.request(
          { method: 'eth_requestAccounts' });
        window.ethereum.on('accountsChanged',
          accs => this.accounts = accs);
        this.web3 = new Web3(window.ethereum);
        this.connected = true;
    },
  },
}
</script>

