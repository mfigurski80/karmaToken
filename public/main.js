import { createApp } from 'vue';
import App from './App.vue';

var cmAddress = "0xDD5D7Bd43be613c21645E07d64a9e89cf59CaE55";
var cmJSON = '/contracts/CollateralManager.json';

window.onload = async () => {
    createApp(App).mount('#root');
    // const cmJ = await fetch(cmJSON)
        // .then(res => res.json());
    // CM = new web3.eth.Contract(cmJ.abi, cmAddress);
    // console.log('CollateralManager Contract Loaded under CM');
    // utils.hydrateHTML('jsCMContractAddress', cmAddress);
    // buildInteractionForms(cmJ.devdoc, cmJ.userdoc);
};

// const parseMethodSignature = (sig) => ({
    // name: sig.split('(')[0],
    // paramTypes: sig.split('(')[1].slice(0,-1).split(','),
// });

// const buildInteractionForms = async (devdoc, userdoc) => {
    // console.log(Object.keys(devdoc.methods).map(sig => {
        // const sigData = parseMethodSignature(sig);
        // const dev = devdoc.methods[sig];
        // const use = userdoc.methods[sig];
        // return {
            // name: sigData.name,
            // notice: use?.notice,
            // description: dev.details,
            // params: dev.params ? Object.keys(dev.params).map((p, id) => ({
                // type: sigData.paramTypes[id],
                // description: dev.params[p],
            // })) : [],
        // }
    // }));
// }
