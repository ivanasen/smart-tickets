const router = require('express').Router();
const EventController = require('../controllers/events');
const TxHistoryController = require('../controllers/tx-history');
const TicketsController = require('../controllers/tickets');

router.route('/events').get(EventController.index);

router.route('/history').get(TxHistoryController.index);

router.route('/tickets').get(TicketsController.index);

module.exports = router;
