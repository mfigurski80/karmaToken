<template>
    <button v-if="!connected" @click="connect">Connect Wallet</button>
    <button v-if="connected" @click="callContractMethod">Call Random Method</button>
    <ContractInteraction :address="address" />
</template>

<script>
import ContractInteraction from './ContractInteraction.vue';

export default {
    name: 'App',
    components: {
        ContractInteraction,
    },
    data: () => ({
        address: "0xDD5D7Bd43be613c21645E07d64a9e89cf59CaE55",
        abiPath: '/contracts/CollateralManager.json',
        connected: false,
        web3: null,
        contract: null,
        contractData: [{
            name: 'CollateralManager',
            address: '0xDD5D7Bd43be613c21645E07d64a9e89cf59CaE55',
            abiPath: '/contracts/CollateralManager.json',
            contract: null,
        }],
        /* web3: new Web3('http://localhost:9545'), */
    }),
    methods: {
        async connect() {
            if (!window.ethereum) {
                alert('Please install metamask or another web3 provider');
                return
            }
            await window.ethereum.request({method: 'eth_requestAccounts'});
            const web3 = new Web3(window.ethereum);
            this.contractData = await Promise.all(this.contractData
                .map(async c => ({
                    ...c,
                    contract: await fetch(c.abiPath)
                        .then(res => res.json())
                        .then(cJ => new web3.eth.Contract(cJ.abi, c.address)),
                })
            ));
            console.log(this.contractData);
            this.web3 = web3;
            this.connected = true;
        },
        async callContractMethod() {
            
        },
    },
}
</script>

