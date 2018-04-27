const web3 = require('./web3').instance;
const contract = require('truffle-contract');

const contractArtifact = require('../build/contracts/SmartTickets.json');
const SmartTickets = contract(contractArtifact);
SmartTickets.setProvider(web3.currentProvider);

if (typeof SmartTickets.currentProvider.sendAsync !== 'function') {
  SmartTickets.currentProvider.sendAsync = function() {
    return SmartTickets.currentProvider.send.apply(
      SmartTickets.currentProvider,
      arguments
    );
  };
}

module.exports = SmartTickets;
