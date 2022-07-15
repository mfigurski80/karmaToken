import { createApp } from './_snowpack/pkg/vue.js';
import App from './App.vue.js';

var cmAddress = "0xDD5D7Bd43be613c21645E07d64a9e89cf59CaE55";
var cmJSON = '/contracts/CollateralManager.json';

window.onload = async () => {
    createApp(App).mount('#root');
};