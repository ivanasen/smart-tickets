const request = require('request-promise-native');
const convertHex = require('convert-hex');
const convertString = require('convert-string');
const _ = require('lodash');
const contract = require('../../config/smart-tickets');
const config = require('../../config/config.json');

const DEFAULT_PAGE_INDEX = 0;
const DEFAULT_PAGE_LIMIT = 10;

class Event {
  static async getAll(pageIndex = DEFAULT_PAGE_INDEX, limit = DEFAULT_PAGE_LIMIT) {
    return await contract.deployed().then(async instance => {
      const eventCount = await instance.getEventCount.call();

      const startIndex = pageIndex * limit + 1; // Start one index ahead because event at index 0 is genesis event
      const endIndex = Math.min(eventCount.add(1), startIndex + limit);
      if (startIndex > eventCount) {
        return [];
      }

      const events = [];
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

  static async getById(id) {
    const event = await instance.getEvent([i]);
    const eventIpfs = JSON.parse(await this._requestFromIpfs(event[1]));
    eventIpfs.eventId = id;

    return eventIpfs;
  }
  
  static async _getAllByDate(startDate, endDate) {
    // TODO: implement this method
  }

  static async _getAllByName(name) {
    // TODO: implement this method
  }

  static async _getAllByLocation() {
    // TODO: implement this method
  }

  static async getAllByParams(sort, location, name, date) {
    // TODO: implement this method
  }

  static async _requestFromIpfs(hexString) {
    const ipfsHashBytes = convertHex.hexToBytes(hexString);
    const ipfsHashString = convertString.bytesToString(ipfsHashBytes);
    return await request(config.ipfsUrl + ipfsHashString);
  }
}

module.exports = Event;
