var SmartTickets = artifacts.require("./SmartTickets.sol");

module.exports = function(deployer) {
  deployer.deploy(SmartTickets);
};
