require('./config/config');
const express = require('express');
const api = require('./routes/api');
const configApp = require('./config/server');
const app = express();

configApp(app, api);

const port = process.env.port;
app.listen(port, () => {
  console.log(`Server is listening on port ${port}`);
});

// app.get('/getAccounts', (req, res) => {
//   console.log("**** GET /getAccounts ****");
//   truffle_connect.start(function (answer) {
//     res.send(answer);
//   })
// });

// app.post('/getBalance', (req, res) => {
//   console.log("**** GET /getBalance ****");
//   console.log(req.body);
//   let currentAcount = req.body.account;

//   truffle_connect.refreshBalance(currentAcount, (answer) => {
//     let account_balance = answer;
//     truffle_connect.start(function(answer){
//       // get list of all accounts and send it along with the response
//       let all_accounts = answer;
//       response = [account_balance, all_accounts]
//       res.send(response);
//     });
//   });
// });

// app.post('/sendCoin', (req, res) => {
//   console.log("**** GET /sendCoin ****");
//   console.log(req.body);

//   let amount = req.body.amount;
//   let sender = req.body.sender;
//   let receiver = req.body.receiver;

//   truffle_connect.sendCoin(amount, sender, receiver, (balance) => {
//     res.send(balance);
//   });
// });
