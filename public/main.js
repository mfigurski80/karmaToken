let web3 = new Web3('http://localhost:9545');
const cmAddress = "0xDD5D7Bd43be613c21645E07d64a9e89cf59CaE55";
let CM;

window.onload = async () => {
    const cmJ = await fetch('/contracts/CollateralManager.json')
        .then(res => res.json());
    CM = new web3.eth.Contract(cmJ.abi, cmAddress);
    console.log('CollateralManager Contract Loaded under CM');
    hydrateHTML('jsCMContractAddress', cmAddress);
    buildInteractionForms(cmJ.devdoc, cmJ.userdoc);
    // attach returned node to #jsCollateralManagerInteractions
};

const parseMethodSignature = (sig) => ({
    name: sig.split('(')[0],
    paramTypes: sig.split('(')[1].slice(0,-1).split(','),
});

const buildInteractionForms = async (devdoc, userdoc) => {
    console.log(Object.keys(devdoc.methods).map(sig => {
        const sigData = parseMethodSignature(sig);
        const dev = devdoc.methods[sig];
        const use = userdoc.methods[sig];
        return {
            name: sigData.name,
            notice: use?.notice,
            description: dev.details,
            params: dev.params ? Object.keys(dev.params).map((p, id) => ({
                type: sigData.paramTypes[id],
                description: dev.params[p],
            })) : [],
        }
    })); 
}

ethereum.on('accountsChanged', (accounts) => {
    console.log(accounts);
});

function handleMintBond() {
    console.log('Handle mint');
}
