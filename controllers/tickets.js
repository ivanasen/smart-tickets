const web3 = require('../config/web3').instance;
const Ticket = require('../data/models/ticket');

class TicketsController {
  static async index(req, res) {
    const address = req.query.address;

    if (!web3.utils.isAddress(address)) {
      res.status(400).send();
      return;
    }

    const tickets = await Ticket.getAll(address);
    res.status(200).send(tickets);
  }
}

module.exports = TicketsController;
