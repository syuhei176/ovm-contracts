const UniversalDecisionContract = artifacts.require('UniversalDecisionContract')
const TestPredicate = artifacts.require('TestPredicate')
const CommitmentContract = artifacts.require('CommitmentContract')

module.exports = function(deployer) {
  deployer
    .deploy(UniversalDecisionContract)
    .then(() => deployer.deploy(TestPredicate))
    .then(() => deployer.deploy(CommitmentContract))
}
