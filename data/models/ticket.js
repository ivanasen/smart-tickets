const contract = require('../../config/smart-tickets');
const { Event } = require('../models/event');

const TICKET_TYPE_ID_INDEX = 0;
const TICKET_TYPE_EVENT_INDEX = 1;
const TICKET_TYPE_PRICE_INDEX = 2;
const TICKET_TYPE_INITIAL_SUPPLY_INDEX = 3;
const TICKET_TYPE_CURRENT_SUPPLY_INDEX = 4;
const TICKET_TYPE_REFUNDABLE_INDEX = 5;

class TicketType {
  constructor(id, eventId, priceInUSDCents, initialSupply, currentSupply, refundable) {
    this.id = id;
    this.eventId = eventId;
    this.priceInUSDCents = priceInUSDCents;
    this.initialSupply = initialSupply;
    this.currentSupply = currentSupply;
    this.refundable = refundable;
  }

  static initWithTuple(tuple) {
    const id = tuple[TICKET_TYPE_ID_INDEX];
    const eventId = tuple[TICKET_TYPE_EVENT_INDEX];
    const priceInUSDCents = tuple[TICKET_TYPE_PRICE_INDEX];
    const initialSupply = tuple[TICKET_TYPE_INITIAL_SUPPLY_INDEX];
    const currentSupply = tuple[TICKET_TYPE_CURRENT_SUPPLY_INDEX];
    const refundable = tuple[TICKET_TYPE_REFUNDABLE_INDEX];

    return new TicketType(id, eventId, priceInUSDCents, initialSupply, currentSupply, refundable);
  }
}

class Ticket {
  constructor(ticketId, ticketType, event) {
    this.ticketId = ticketId;
    this.ticketType = ticketType;
    this.event = event;
  }

  static async getAll(address) {
    return await contract.deployed().then(async instance => {
      const ticketIds = await instance.getTicketsForOwner(address);

      const tickets = await Promise.all(
        ticketIds.filter(id => id != 0).map(async id => {          
            const ticketType = await Ticket._getTicketTypeForTicket(id, instance);
            const event = await Event.getById(ticketType.eventId, instance);
            return new Ticket(id, ticketType, event);          
        })
      );

      return tickets;
    });
  }

  static async _getTicketTypeForTicket(id, contract) {
    const ticketTypeTuple = await contract.getTicketTypeForTicket(id);
    const ticketType = TicketType.initWithTuple(ticketTypeTuple);
    return ticketType;
  }
}

module.exports = Ticket;
