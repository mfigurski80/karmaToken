// Snowpack Configuration File
// See all supported options: https://www.snowpack.dev/reference/configuration

/** @type {import("snowpack").SnowpackUserConfig } */
module.exports = {
  root: 'public',
  workspaceRoot: '.',
  mount: {
    'public': '/',
    'build/contracts': { url: '/contracts', static: true },
    'coverage': { url: '/coverage', static: true },
  },
  plugins: [
    '@snowpack/plugin-vue',
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
  optimize: {
    bundle: true,
    minify: true,
    target: 'es2020'
  },
};
