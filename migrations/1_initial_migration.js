const Migrations = artifacts.require("Migrations");

module.exports = function (deployer) {
  console.log("Deploying Migrations contract...");
  // console.log(Migrations);
  deployer.deploy(Migrations);
};
