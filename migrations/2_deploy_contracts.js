// var ConvertLib = artifacts.require("./ConvertLib.sol");
var SmartTicketsCore = artifacts.require("./SmartTicketsCore.sol");
module.exports = function(deployer) {
  // deployer.deploy(ConvertLib);
  deployer.deploy(SmartTicketsCore);
};
