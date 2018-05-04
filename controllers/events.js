const { Event, ORDER_TYPES } = require('../data/models/event');
const web3 = require('../config/web3').instance;

const DEFAULT_PAGE_INDEX = 0;
const DEFAULT_PAGE_LIMIT = 10;
const DEFAULT_PAGE_ORDER = ORDER_TYPES.recent;
class EventController {
  static async index(req, res) {
    const page = parseInt(req.query.page) || DEFAULT_PAGE_INDEX;
    const limit = parseInt(req.query.limit) || DEFAULT_PAGE_LIMIT;
    const order = req.query.order || DEFAULT_PAGE_ORDER;

    const creatorAddress = req.query.address;

    if (isNaN(page) || page < 0) {
      res.status(400).send('Invalid page index');
    } else if (creatorAddress) {
      if (web3.utils.isAddress(creatorAddress)) {
        const events = await Event.getAllForCreator(creatorAddress);
        res.send(events);
      } else {
        res.status(400).send('Invalid Address')
      }    

    } else {
      const events = await Event.getAll(page, limit, order);
      res.send(events);
    }
  }
}

module.exports = EventController;
