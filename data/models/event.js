const request = require('request-promise-native');
const convertHex = require('convert-hex');
const convertString = require('convert-string');
const _ = require('lodash');
const contract = require('../../config/smart-tickets');
const config = require('../../config/config.json');

class Event {
  static async get(pageIndex = 0, limit = 10) {
    return await contract.deployed().then(async instance => {
      const eventCount = await instance.getEventCount.call();

      const events = [];

      const startIndex = pageIndex * limit + 1; // Start one index ahead because event at index 0 is genesis event
      if (startIndex > eventCount) {
        return [];
      }
      const endIndex = Math.min(eventCount.add(1), startIndex + limit);
      
      await Promise.all(
        _.range(startIndex, endIndex).map(async id => {
          const event = await instance.getEvent(id);
          const eventIpfs = JSON.parse(await this._requestFromIpfs(event[1]));
          eventIpfs.eventId = id;
          events.push(eventIpfs);
        })
      );

      return events;
    });
  }

  static async byId(id) {
    const event = await instance.getEvent([i]);
    const ipfsHashBytes = convertHex.hexToBytes(event[1]);

    const ipfsHashString = convertString.bytesToString(ipfsHashBytes);
    return ipfsHashString;
  }

  static async byName(name) {}

  static async _requestFromIpfs(hexString) {
    const ipfsHashBytes = convertHex.hexToBytes(hexString);
    const ipfsHashString = convertString.bytesToString(ipfsHashBytes);
    return await request(config.ipfsUrl + ipfsHashString);
  }
}

module.exports = Event;
