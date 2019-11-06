/* contract imports */
const chai = require('chai');
const {createMockProvider, deployContract, getWallets, solidity, link} = require('ethereum-waffle');
const UniversalAdjudicationContract = require('../build/UniversalAdjudicationContract');
const Utils = require('../build/Utils');
const AndPredicate = require('../build/AndPredicate');
const NotPredicate = require('../build/NotPredicate');
const TestPredicate = require('../build/TestPredicate');
const ethers = require('ethers');
const abi = new ethers.utils.AbiCoder();

chai.use(solidity);
chai.use(require('chai-as-promised'));
const {expect, assert} = chai;

describe('AndPredicate', () => {
  let provider = createMockProvider();
  let wallets = getWallets(provider);
  let wallet = wallets[0];
  let utils;
  let testPredicate, andPredicate, notPredicate, adjudicationContract;
  let trueProperty, andProperty;

  before(async () => {
		utils = await deployContract(wallet, Utils, []);
  })

  beforeEach(async () => {
    adjudicationContract = await deployContract(wallet, UniversalAdjudicationContract, [utils.address]);
    notPredicate = await deployContract(wallet, NotPredicate, [adjudicationContract.address]);
    andPredicate = await deployContract(wallet, AndPredicate, [adjudicationContract.address, notPredicate.address]);
    testPredicate = await deployContract(wallet, TestPredicate, [adjudicationContract.address]);
    trueProperty = {
      predicateAddress: testPredicate.address,
      inputs: ['0x01'],
      properties: []
    };
    andProperty = {
      predicateAddress: andPredicate.address,
      inputs: [],
      properties: [
        abi.encode(['tuple(address, bytes[], bytes[])'], [[testPredicate.address, ['0x01'], []]]),
        abi.encode(['tuple(address, bytes[], bytes[])'], [[testPredicate.address, [], []]]),
      ]
    };
    notTrueProperty = {
      predicateAddress: notPredicate.address,
      inputs: [],
      properties: [abi.encode(['tuple(address, bytes[], bytes[])'], [[testPredicate.address, ['0x01'], []]])]
    };
    notFalseProperty = {
      predicateAddress: notPredicate.address,
      inputs: [],
      properties: [abi.encode(['tuple(address, bytes[], bytes[])'], [[testPredicate.address, [], []]])]
    };
  });

  describe('isValidChallenge', () => {
    it('validate challenge with 0', async () => {
      const challengeInput = abi.encode(['uint256'], [0]);
      await adjudicationContract.claimProperty(andProperty);
      await adjudicationContract.claimProperty(notTrueProperty);
      const gameId = await adjudicationContract.getPropertyId(andProperty);
      const challengingGameId = await adjudicationContract.getPropertyId(notTrueProperty);
      await adjudicationContract.challenge(gameId, [challengeInput], challengingGameId);
      const game = await adjudicationContract.getGame(gameId);
      assert.equal(game.challenges.length, 1);
    });
    it('validate challenge with 1', async () => {
      const challengeInput = abi.encode(['uint256'], [1]);
      await adjudicationContract.claimProperty(andProperty);
      await adjudicationContract.claimProperty(notFalseProperty);
      const gameId = await adjudicationContract.getPropertyId(andProperty);
      const challengingGameId = await adjudicationContract.getPropertyId(notFalseProperty);
      await adjudicationContract.challenge(gameId, [challengeInput], challengingGameId);
      const game = await adjudicationContract.getGame(gameId);
      assert.equal(game.challenges.length, 1);
    });
    it('fail to validate challenge with 1', async () => {
      const challengeInput = abi.encode(['uint256'], [1]);
      await adjudicationContract.claimProperty(andProperty);
      await adjudicationContract.claimProperty(trueProperty);
      const gameId = await adjudicationContract.getPropertyId(andProperty);
      const challengingGameId = await adjudicationContract.getPropertyId(trueProperty);
      await expect(adjudicationContract.challenge(gameId, [challengeInput], challengingGameId)).to.be.reverted;
    });
  });
});
