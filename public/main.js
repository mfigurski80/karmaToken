import { createApp } from 'vue';
import App from './App.vue';

var cmAddress = "0xDD5D7Bd43be613c21645E07d64a9e89cf59CaE55";
var cmJSON = '/contracts/CollateralManager.json';

window.onload = async () => {
    createApp(App).mount('#root');
};