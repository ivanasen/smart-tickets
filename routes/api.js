const router = require('express').Router();
const EventController = require('../controllers/events');
const TxHistoryController = require('../controllers/tx-history');

router.route('/events').get(EventController.index);
router.route('/history').get(TxHistoryController.index);

module.exports = router;
