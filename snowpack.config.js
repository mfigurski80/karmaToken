// Snowpack Configuration File
// See all supported options: https://www.snowpack.dev/reference/configuration

/** @type {import("snowpack").SnowpackUserConfig } */
module.exports = {
  mount: {
    'public': '/',
    'build/contracts': '/contracts',
    'coverage': '/coverage',
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
