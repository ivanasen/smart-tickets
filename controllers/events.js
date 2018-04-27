const Event = require('../data/models/event');

class EventController {
  static async index(req, res) {
    const events = await Event.all();
    res.send(events);
  }
}

module.exports = EventController;
