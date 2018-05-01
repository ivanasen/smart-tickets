const convertHex = require('convert-hex');
const convertString = require('convert-string');
const request = require('request-promise-native');
const _ = require('lodash');
const contract = require('../../config/smart-tickets');
const config = require('../../config/config.json');

const INDEX_EVENT_ID = 1;

const ORDER_TYPES = {
  recent: 'recent',
  old: 'old',
  popular: 'popular'
};
class Event {
  static async getAll(pageIndex = DEFAULT_PAGE_INDEX, limit, order) {
    return await contract.deployed().then(async instance => {
      const eventCount = await instance.getEventCount.call();

      const events = [];
      switch (order) {
        case ORDER_TYPES.popular: {
          const eventsContract = await Promise.all(
            _.range(1, eventCount).map(async id => {
              const event = await instance.getEvent(id);
              events.push(event);
            })
          )

          break;
        }

        case ORDER_TYPES.old: {
          const startIndex = pageIndex * limit + 1; // Start one index ahead because event at index 0 is genesis event
          const endIndex = Math.min(eventCount.add(1), startIndex + limit);
          if (startInde > eventCount) {
            return [];
          }

          await Promise.all(
            _.range(startIndex, endIndex).map(async id => {
              const event = await instance.getEvent(id);
              const response = await this._requestFromIpfs(
                event[INDEX_EVENT_ID]
              );
              const eventIpfs = JSON.parse(response);
              eventIpfs.eventId = id;
              events.push(eventIpfs);
            })
          );
          break;
        }
        case ORDER_TYPES.recent:
        default: {
          const endIndex = Math.max(1, eventCount - pageIndex * limit + 1);
          const startIndex = Math.max(1, endIndex - limit); // Stop at first index where is the last event

          await Promise.all(
            _.rangeRight(startIndex, endIndex).map(async id => {
              const event = await instance.getEvent(id);
              const response = await this._requestFromIpfs(
                event[INDEX_EVENT_ID]
              );
              const eventIpfs = JSON.parse(response);
              eventIpfs.eventId = id;
              events.push(eventIpfs);
            })
          );
          break;
        }
      }

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

  static async getAllByParams(sort, location, name, date) {
    // TODO: implement this method
  }

  static async _requestFromIpfs(hexString) {
    const ipfsHashBytes = convertHex.hexToBytes(hexString);
    const ipfsHashString = convertString.bytesToString(ipfsHashBytes);
    return await request(config.ipfsUrl + ipfsHashString);
  }
}

module.exports = { Event, ORDER_TYPES };
