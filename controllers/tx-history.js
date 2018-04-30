const web3 = require('../config/web3').instance;
const { ropstenEtherscanApiKey, ropstenEtherscanBaseUrl } = require('../config/config.json');
const fetch = require('node-fetch');

class TxHistoryController {
  static async index(req, res) {
    const address = req.query.address;
    const page = req.query.page;
    const sort = req.query.sort;
    const offset = req.query.offset;

    if (web3.utils.isAddress(address)) {
      const history = await TxHistoryController._requestAddressHistory(address, page, offset, sort);
      res.status(200).send(await history.json());
      return;
    }

    res.status(400).send();
    return;
  }

  static async _requestAddressHistory(address, page, offset, sort) {
    return fetch(`${ropstenEtherscanBaseUrl}?module=account&action=txlist&address=${address}&sort=${sort}&page=${page}&offset=${offset}&apikey=${ropstenEtherscanApiKey}`);
  }
}

module.exports = TxHistoryController;