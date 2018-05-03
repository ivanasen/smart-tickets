const web3 = require('../config/web3').instance;
const { ropstenEtherscanApiKey, ropstenEtherscanBaseUrl } = require('../config/config.json');
const fetch = require('node-fetch');
const contract = require('../config/smart-tickets');
const { convertTimestampToMillis } = require('../utils/util');

class TxHistoryController {
  static async index(req, res) {
    const address = req.query.address;
    const page = req.query.page;
    const sort = req.query.sort;
    const offset = req.query.offset;

    await contract.deployed().then(async instance => {
      if (web3.utils.isAddress(address)) {
        const response = await TxHistoryController._requestAddressHistory(
          address,
          page,
          offset,
          sort
        );

        const history = (await response.json()).result;

        await Promise.all(
          history.map(async tx => {
            tx.valueUsd = await TxHistoryController._convertWeiToUsd(
              instance,
              tx.value
            );
            tx.timestamp = convertTimestampToMillis(tx.timestamp);

            return tx;
          })
        );

        res.status(200).send(history);
        return;
      }

      res.status(400).send();
    });
  }

  static async _requestAddressHistory(address, page, offset, sort) {
    return fetch(
      `${ropstenEtherscanBaseUrl}?module=account&action=txlist&address=${address}&sort=${sort}&page=${page}&offset=${offset}&apikey=${ropstenEtherscanApiKey}`
    );
  }

  static async _convertWeiToUsd(contract, wei) {
    const oneUsdCentInWei = await contract.getOneUSDCentInWei.call();
    const usdCents = wei / oneUsdCentInWei;
    return usdCents / 100;
  }
}

module.exports = TxHistoryController;
