require('./config/config');
const express = require('express');
const api = require('./routes/api');
const configApp = require('./config/server');
const app = express();

configApp(app, api);

const port = process.env.PORT;
app.listen(port, () => {
  console.log(`Server is listening on port ${port}`);
});
