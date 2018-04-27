const web3 = require('../../config/web3').instance
const contract = require('truffle-contract')

const contractArtifact = require('../../build/contracts/SmartTickets.json')
const SmartTickets = contract(contractArtifact)
SmartTickets.setProvider(web3.currentProvider)

if (typeof SmartTickets.currentProvider.sendAsync !== 'function') {
  SmartTickets.currentProvider.sendAsync = function () {
    return SmartTickets.currentProvider.send.apply(
      SmartTickets.currentProvider,
      arguments
    )
  }
}

class Event {
  static async all(limit) {
    return await SmartTickets.deployed().then(async instance => {

      const eventCount = await instance.getEventCount.call()

      return eventCount
    })
  }

  static async byId(id) {}

  static async byName(name) {}
}

module.exports = Event