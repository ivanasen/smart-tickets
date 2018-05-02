const Web3 = require('web3');
const config = require('./config.json');

const WEB3_KEY = 'web3';

global[WEB3_KEY] = new Web3(
  new Web3.providers.HttpProvider(config.ethereumNodeUrlRopsten)
);

const singleton = {};
Object.defineProperty(singleton, 'instance', {
  get() {
    return global[WEB3_KEY];
  }
});
Object.freeze(singleton);

console.log(`Web3 Connected to: ${singleton.instance.currentProvider.host}`);

module.exports = singleton;
