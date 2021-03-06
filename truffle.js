var HDWalletProvider = require('truffle-hdwallet-provider');
var mnemonic =
  'devote barely shoulder rate west conduct fatigue robust never doctor join sick';
var infuraRopstenUrl = 'https://ropsten.infura.io/YAcKUvG0v0T60082XYEO';

module.exports = {
  networks: {
    development: {
      host: '127.0.0.1',
      port: 8545,
      network_id: '*' // Match any network id
    },
    ropsten: {
      provider: function() {
        return new HDWalletProvider(mnemonic, infuraRopstenUrl);
      },      
      network_id: 3,
      gas: 4700000,
      gasPrice: 21000000000
    }
  }
};
