/* contract imports */
const chai = require('chai');
const {createMockProvider, deployContract, getWallets, solidity, link} = require('ethereum-waffle');
const UniversalAdjudicationContract = require('../build/UniversalAdjudicationContract');
const Utils = require('../build/Utils');
const AndPredicate = require('../build/AndPredicate');
const ForAllSuchThatQuantifier = require('../build/ForAllSuchThatQuantifier');
const NotPredicate = require('../build/NotPredicate');
const TestPredicate = require('../build/TestPredicate');
const ethers = require('ethers');
const abi = new ethers.utils.AbiCoder();

chai.use(solidity);
chai.use(require('chai-as-promised'));
const {expect, assert} = chai;

describe('ForAllSuchThatQuantifier', () => {
  let provider = createMockProvider();
  let wallets = getWallets(provider);
  let wallet = wallets[0];
  let utils;
  let testPredicate, andPredicate, notPredicate, forAllSuchThat, adjudicationContract;
  let trueProperty, andProperty;

  before(async () => {
		utils = await deployContract(wallet, Utils, []);
  })

  beforeEach(async () => {
    adjudicationContract = await deployContract(wallet, UniversalAdjudicationContract, [utils.address]);
    notPredicate = await deployContract(wallet, NotPredicate, [adjudicationContract.address]);
    andPredicate = await deployContract(wallet, AndPredicate, [adjudicationContract.address, notPredicate.address]);
    forAllSuchThat = await deployContract(wallet, ForAllSuchThatQuantifier, [adjudicationContract.address, notPredicate.address]);
    testPredicate = await deployContract(wallet, TestPredicate, [adjudicationContract.address]);
    trueProperty = {
      predicateAddress: testPredicate.address,
      inputs: ['0x01']
    };
    forAllSuchThatProperty = {
      predicateAddress: forAllSuchThat.address,
      inputs: [
        abi.encode(['tuple(address, bytes[])'], [[testPredicate.address, []]]),
        '0x50',
        abi.encode(['tuple(address, bytes[])'], [[testPredicate.address, ['0x50']]]),
      ]
    };
    notTrueProperty = {
      predicateAddress: notPredicate.address,
      inputs: [abi.encode(['tuple(address, bytes[])'], [[testPredicate.address, ['0x01']]])]
    };
    notFalseProperty = {
      predicateAddress: notPredicate.address,
      inputs: [abi.encode(['tuple(address, bytes[])'], [[testPredicate.address, []]])]
    };
  });

  describe('isValidChallenge', () => {
    it('validate challenge with 0x01 to for all t in Test() such that Test(t)', async () => {
      const challengeInput = '0x01';
      await adjudicationContract.claimProperty(forAllSuchThatProperty);
      await adjudicationContract.claimProperty(notTrueProperty);
      const gameId = await adjudicationContract.getPropertyId(forAllSuchThatProperty);
      const challengingGameId = await adjudicationContract.getPropertyId(notTrueProperty);
      await adjudicationContract.challenge(gameId, [challengeInput], challengingGameId);
      const game = await adjudicationContract.getGame(gameId);
      assert.equal(game.challenges.length, 1);
    });
  });
});
