const convertHex = require('convert-hex');
const convertString = require('convert-string');
const request = require('request-promise-native');
const _ = require('lodash');
const contract = require('../../config/smart-tickets');
const config = require('../../config/config.json');
const { convertTimestampToMillis } = require('../../utils/util');

const INDEX_TIMESTAMP = 0;
const INDEX_IPFS_HASH = 1;
const INDEX_PROMOTION_LEVEL = 5;
const INDEX_EARNINGS = 4;

const ORDER_TYPES = {
  recent: 'recent',
  old: 'old',
  popular: 'popular'
};
class Event {
  // TODO: convert to OOP aproach
  // constructor() {

  // }

  static async getAll(pageIndex, limit, order) {
    return await contract.deployed().then(async instance => {
      const eventCount = await instance.getEventCount.call();

      const events = [];
      switch (order) {
        case ORDER_TYPES.popular: {
          const eventsContract = await Promise.all(
            // Start at index 1 since at index 0 is the genesis event
            _.range(1, eventCount.add(1)).map(async id =>
              Event._getEvent(instance, id)
            )
          );

          eventsContract.sort(
            (a, b) => b[INDEX_PROMOTION_LEVEL] - a[INDEX_PROMOTION_LEVEL]
          );

          const startIndex = pageIndex * limit;
          const endIndex = Math.min(eventsContract.length, startIndex + limit);
          if (startIndex >= eventCount) {
            return [];
          }

          await Promise.all(
            _.range(startIndex, endIndex).map(async i => {
              const event = eventsContract[i];
              const response = await this._requestFromIpfs(
                event[INDEX_IPFS_HASH]
              );
              const eventIpfs = JSON.parse(response);

              eventIpfs.eventId = event.eventId;
              eventIpfs.tickets = event.ticketTypes;
              eventIpfs.earnings = event[INDEX_EARNINGS];
              eventIpfs.timestamp = convertTimestampToMillis(
                event[INDEX_TIMESTAMP]
              );
              events.push(eventIpfs);
            })
          );

          break;
        }

        case ORDER_TYPES.old: {
          const startIndex = pageIndex * limit + 1; // Start one index ahead because event at index 0 is genesis event
          const endIndex = Math.min(eventCount.add(1), startIndex + limit);
          if (startIndex > eventCount) {
            return [];
          }

          await Promise.all(
            _.range(startIndex, endIndex).map(async id => {
              const event = await instance.getEvent(id);
              const response = await this._requestFromIpfs(
                event[INDEX_IPFS_HASH]
              );
              const eventIpfs = JSON.parse(response);
              eventIpfs.eventId = id;
              eventIpfs.tickets = await Event._getTicketTypesForEvent(
                instance,
                id
              );
              eventIpfs.timestamp = convertTimestampToMillis(
                event[INDEX_TIMESTAMP]
              );
              eventIpfs.earnings = event[INDEX_EARNINGS];
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
                event[INDEX_IPFS_HASH]
              );
              const eventIpfs = JSON.parse(response);
              eventIpfs.eventId = id;
              eventIpfs.tickets = await Event._getTicketTypesForEvent(
                instance,
                id
              );
              eventIpfs.earnings = event[INDEX_EARNINGS];
              eventIpfs.timestamp = convertTimestampToMillis(
                event[INDEX_TIMESTAMP]
              );
              events.push(eventIpfs);
            })
          );
          break;
        }
      }

      return events;
    });
  }

  static async getAllForCreator(address) {
    return await contract.deployed().then(async instance => {
      const eventIds = await instance.getEventIdsForCreator(address);

      if (!eventIds || eventIds.length == 0) {
        return [];
      }

      const events = await Promise.all(eventIds.map(async id => {
        return await Event.getById(id, instance);
      }));
      return events;
    });
  }

  static async getById(id, contract) {
    const event = await contract.getEvent([id]);
    const eventIpfs = JSON.parse(
      await Event._requestFromIpfs(event[INDEX_IPFS_HASH])
    );
    eventIpfs.eventId = id;
    eventIpfs.timestamp = convertTimestampToMillis(event[INDEX_TIMESTAMP]);
    eventIpfs.tickets = await Event._getTicketTypesForEvent(contract, id);
    eventIpfs.earnings = event[INDEX_EARNINGS];

    return eventIpfs;
  }

  static async _getAllByDate(startDate, endDate) {
    // TODO: implement this method
  }

  static async _getAllByName(name) {
    // TODO: implement this method
  }

  static async _getTicketTypesForEvent(contract, eventId) {
    const count = await contract.getTicketTypesCountForEvent(eventId);

    const ticketTypes = await Promise.all(
      _.range(0, count).map(async ticketIndex => {
        const ticketTuple = await contract.getTicketTypeForEvent(
          eventId,
          ticketIndex
        );
        return Event._convertTicketTupleToTicketType(ticketTuple);
      })
    );
    return ticketTypes;
  }

  static _convertTicketTupleToTicketType(ticketTuple) {
    const ticketTypeId = ticketTuple[0].toNumber();
    const eventId = ticketTuple[1].toNumber();
    const priceInUSDCents = ticketTuple[2].toNumber();
    const initialSupply = ticketTuple[3].toNumber();
    const currentSupply = ticketTuple[4].toNumber();
    const refundable = ticketTuple[5].toNumber();
    return {
      ticketTypeId,
      eventId,
      priceInUSDCents,
      initialSupply,
      currentSupply,
      refundable
    };
  }

  static async _getEvent(contract, id) {
    const event = await contract.getEvent(id);

    const ticketTypes = await Event._getTicketTypesForEvent(contract, id);

    event.tickets = ticketTypes;
    event.eventId = id;
    return event;
  }

  static async _requestFromIpfs(hexString) {
    const ipfsHashBytes = convertHex.hexToBytes(hexString);
    const ipfsHashString = convertString.bytesToString(ipfsHashBytes);
    return await request(config.ipfsUrl + ipfsHashString);
  }
}

module.exports = { Event, ORDER_TYPES };
