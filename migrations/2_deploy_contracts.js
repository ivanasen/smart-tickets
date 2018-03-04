// var ConvertLib = artifacts.require("./ConvertLib.sol");
var SmartTickets = artifacts.require("./SmartTickets.sol");
module.exports = function(deployer) {
  // deployer.deploy(ConvertLib);
  deployer.deploy(SmartTickets);
};
