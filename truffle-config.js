const HDWalletProvider = require('@truffle/hdwallet-provider');
require('dotenv').config();

module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",     // Localhost (default: none)
      port: 9545,            // Standard Ethereum port (default: none)
      network_id: "*",       // Any network (default: none)
      //  gasPrice: 1,
    },
    test: {
      networkCheckTimeout: 20000,
      host: "173.62.205.157",
      port: 8545,
      network_id: "3072",
      skipDryRun: true,
    },
    localTest: {
      networkCheckTimeout: 20000,
      host: "10.7.8.120",
      port: 8545,
      network_id: "3072",
    },
    goerli: {
      provider: () => new HDWalletProvider({
        mnemonic: process.env.MNEMONIC, 
        providerOrUrl: "https://goerli.infura.io/v3/" + process.env.INFURA_GORLI_API_KEY,
      }),
      network_id: "5",
      gasPrice: 10000000000,
      production: true,
    },
  },

  // Set default mocha options here, use special reporters etc.
  mocha: {
    // timeout: 100000
    reporter: 'eth-gas-reporter',
    reporterOptions: {
      excludeContracts: ['Migrations'],
      coinmarketcap: process.env.COINMARKETCAP_API_KEY,
      currency: 'USD',
      gasPrice: 30, // gwei
    }
  },

  // Configure your compilers
  compilers: {
    solc: {
      version: "0.8.6",    // Fetch exact version from solc-bin (default: truffle's version)
      docker: true,        // Use "0.5.1" you've installed locally with docker (default: false)
      settings: {          // See the solidity docs for advice about optimization and evmVersion
        optimizer: {
          enabled: true,
          runs: 1000,
        }
        //  evmVersion: "byzantium"
      }
    }
  },

  plugins: ["truffle-contract-size", "solidity-coverage"],

  // Truffle DB is currently disabled by default; to enable it, change enabled: false to enabled: true
  //
  // Note: if you migrated your contracts prior to enabling this field in your Truffle project and want
  // those previously migrated contracts available in the .db directory, you will need to run the following:
  // $ truffle migrate --reset --compile-all

  // db: {
  //   enabled: false
  // }
};
