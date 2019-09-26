const Migrations = artifacts.require("Migrations");

module.exports = function(deployer) {
  console.log("Hello");
  deployer.deploy(Migrations);
};
