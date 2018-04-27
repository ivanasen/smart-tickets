const router = require('express').Router();

const eventController = require('../controllers/events');

router.route('/events').get(eventController.index);

module.exports = router;
