const cors = require('cors');
const helmet = require('helmet');
const bodyParser = require('body-parser');
const morgan = require('morgan');
require('../config/web3');
module.exports = (app, api) => {
  app.use(cors());
  app.use(morgan('tiny'));
  app.use(helmet());
  app.use(bodyParser.json());
  app.use(bodyParser.urlencoded({ extended: true }));

  app.use('/api', api);

  app.use((req, res) => {
    res.status(404).end();
  });
};
