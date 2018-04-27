const Event = require('../data/models/event');

class EventController {
  static async index(req, res) {    
    const page = parseInt(req.query.page);

    if (isNaN(page) || page < 0) {
      res.status(400).send('Invalid page index');
    } else {
      const events = await Event.get(page);
      res.send(events);
    }
  }
}

module.exports = EventController;
