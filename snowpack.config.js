// Snowpack Configuration File
// See all supported options: https://www.snowpack.dev/reference/configuration

/** @type {import("snowpack").SnowpackUserConfig } */
module.exports = {
  mount: {
    'public': '/',
    'build/contracts': '/contracts',
    'coverage': '/coverage',
    'testnet_addresses.txt': '/testnet_addresses.txt',
    /* ... */
  },
  plugins: [
    '@snowpack/plugin-vue',
    /* ... */
  ],
  packageOptions: {
    /* ... */
  },
  devOptions: {
    /* ... */
  },
  buildOptions: {
    out: 'publicBuild',
    /* ... */
  },
};
