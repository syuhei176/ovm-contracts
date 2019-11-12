/* contract imports */
const chai = require('chai');
const {createMockProvider, deployContract, getWallets, solidity, link} = require('ethereum-waffle');
const UniversalAdjudicationContract = require('../build/UniversalAdjudicationContract');
const Utils = require('../build/Utils');
const NotPredicate = require('../build/NotPredicate');
const TestPredicate = require('../build/TestPredicate');
const ethers = require('ethers');
const abi = new ethers.utils.AbiCoder();
const { increaseBlocks } = require('./helpers/increaseBlocks');
const { getGameIdFromProperty } = require('./helpers/getGameId')

chai.use(solidity);
chai.use(require('chai-as-promised'));
const {expect, assert} = chai;

describe('UniversalAdjudicationContract', () => {
  let provider = createMockProvider();
  let wallets = getWallets(provider);
  let wallet = wallets[0];
  let adjudicationContract;
  let utils;
  let testPredicate, notPredicate;
  let trueProperty, notProperty, notFalseProperty;
  const Undecided = 0;
  const True = 1;
  const False = 2;

  before(async () => {
		utils = await deployContract(wallet, Utils, []);
  })

  beforeEach(async () => {
    adjudicationContract = await deployContract(wallet, UniversalAdjudicationContract, [utils.address]);
    notPredicate = await deployContract(wallet, NotPredicate, [adjudicationContract.address, utils.address]);
    testPredicate = await deployContract(wallet, TestPredicate, [adjudicationContract.address, utils.address]);
    trueProperty = {
      predicateAddress: testPredicate.address,
      inputs: ['0x01']
    };
    falseProperty = {
      predicateAddress: testPredicate.address,
      inputs: []
    };
    notProperty = {
      predicateAddress: notPredicate.address,
      inputs: [abi.encode(['tuple(address, bytes[])'], [[testPredicate.address, ['0x01']]])]
    };
    notFalseProperty = {
      predicateAddress: notPredicate.address,
      inputs: [abi.encode(['tuple(address, bytes[])'], [[testPredicate.address, []]])]
    };
  });

  describe('claimProperty', () => {
    it('adds a claim', async () => {
      await adjudicationContract.claimProperty(notProperty);
      const claimId = getGameIdFromProperty(notProperty);
      const game = await adjudicationContract.getGame(claimId);

      // check newly stored property is equal to the claimed property
      assert.equal(game.property.predicateAddress, notProperty.predicateAddress);
      assert.equal(game.property.input, notProperty.input);
      assert.equal(game.decision, Undecided);
    });
    it('fails to add an already claimed property and throws Error', async () => {
      // claim a property
      await adjudicationContract.claimProperty(trueProperty);
      // check if the second call of the claimProperty function throws an error
      assert(await expect(adjudicationContract.claimProperty(trueProperty)).to.be.rejectedWith(Error));
    });
  });

  describe('challenge', () => {
    it('not(true) is challenged by true', async () => {
      await adjudicationContract.claimProperty(notProperty);
      await adjudicationContract.claimProperty(trueProperty);
      const gameId = getGameIdFromProperty(notProperty);
      const challengingGameId = getGameIdFromProperty(trueProperty);
      await adjudicationContract.challenge(gameId, ["0x"], challengingGameId);
      const game = await adjudicationContract.getGame(gameId);

      assert.equal(game.challenges.length, 1);
    });
    it('not(true) fail to be challenged by not(false)', async () => {
      await adjudicationContract.claimProperty(notProperty);
      await adjudicationContract.claimProperty(notFalseProperty);
      const gameId = getGameIdFromProperty(notProperty);
      const challengingGameId = getGameIdFromProperty(notFalseProperty);
      await expect(adjudicationContract.challenge(gameId, ["0x"], challengingGameId)).to.be.reverted;
    });
  });

  describe('decideClaimToFalse', () => {
    it('not(true) decided false with a challenge by true', async () => {
      await adjudicationContract.claimProperty(notProperty);
      await adjudicationContract.claimProperty(trueProperty);
      const gameId = getGameIdFromProperty(notProperty);
      const challengingGameId = getGameIdFromProperty(trueProperty);
      await adjudicationContract.challenge(gameId, ["0x"], challengingGameId);
      await testPredicate.decideTrue(['0x01']);
      await adjudicationContract.decideClaimToFalse(gameId, challengingGameId);
      const game = await adjudicationContract.getGame(gameId);
      // game should be decided false
      assert.equal(game.decision, False);
    });
    it('not(false) fail to decided false without challenges', async () => {
      await adjudicationContract.claimProperty(notFalseProperty);
      await adjudicationContract.claimProperty(falseProperty);
      const gameId = getGameIdFromProperty(notFalseProperty);
      const challengingGameId = getGameIdFromProperty(falseProperty);
      await adjudicationContract.challenge(gameId, ["0x"], challengingGameId);
      await expect(adjudicationContract.decideClaimToFalse(gameId, challengingGameId)).to.be.reverted;
    });
  });

  describe('decideClaimToTrue', () => {
    it('not(true) decided true because there are no challenges', async () => {
      await adjudicationContract.claimProperty(notProperty);
      const gameId = getGameIdFromProperty(notProperty);
      // increase 10 blocks to pass dispute period
      await increaseBlocks(wallets, 10);
      await adjudicationContract.decideClaimToTrue(gameId);

      const game = await adjudicationContract.getGame(gameId);
      // game should be decided true
      assert.equal(game.decision, True);
    });
    it('fail to decided true because dispute period has not passed', async () => {
      await adjudicationContract.claimProperty(notProperty);
      const gameId = getGameIdFromProperty(notProperty);
      await expect(adjudicationContract.decideClaimToTrue(gameId)).to.be.reverted;
    });
  });

  describe('setPredicateDecision', () => {
    it('decide bool(true) decided true', async () => {
      await adjudicationContract.claimProperty(trueProperty);
      const gameId = getGameIdFromProperty(trueProperty);
      await testPredicate.decideTrue(trueProperty.inputs);
      const game = await adjudicationContract.getGame(gameId);
      assert.equal(game.decision, True);
    });
    it('decide bool(false) decided false', async () => {
      await adjudicationContract.claimProperty(falseProperty);
      const gameId = getGameIdFromProperty(falseProperty);
      await testPredicate.decideFalse(falseProperty.inputs);
      const game = await adjudicationContract.getGame(gameId);
      assert.equal(game.decision, False);
    });
    it('fail to call setPredicateDecision directlly', async () => {
      await adjudicationContract.claimProperty(trueProperty);
      const gameId = getGameIdFromProperty(trueProperty);
      await expect(adjudicationContract.setPredicateDecision(gameId, true))
        .to.be.reverted
    });
  });

  describe('removeChallenge', () => {
    // We can remove "False" challenge from game.
    it('remove false from not(false)', async () => {
      await adjudicationContract.claimProperty(notFalseProperty);
      await adjudicationContract.claimProperty(falseProperty);
      const gameId = getGameIdFromProperty(notFalseProperty);
      const challengeGameId = getGameIdFromProperty(falseProperty);
      await adjudicationContract.challenge(gameId, ["0x"], challengeGameId);
      await testPredicate.decideFalse(falseProperty.inputs);
      await adjudicationContract.removeChallenge(gameId, challengeGameId);
      const game = await adjudicationContract.getGame(gameId);
      assert.equal(game.challenges.length, 0);
    });
    it('fail to remove undecided challenge', async () => {
      await adjudicationContract.claimProperty(notFalseProperty);
      await adjudicationContract.claimProperty(falseProperty);
      const gameId = getGameIdFromProperty(notFalseProperty);
      const challengeGameId = getGameIdFromProperty(falseProperty);
      await adjudicationContract.challenge(gameId, ["0x"], challengeGameId);
      await expect(adjudicationContract.removeChallenge(gameId, challengeGameId))
        .to.be.reverted
    });
    it('fail to remove true from not(true)', async () => {
      await adjudicationContract.claimProperty(notProperty);
      await adjudicationContract.claimProperty(trueProperty);
      const gameId = getGameIdFromProperty(notProperty);
      const challengeGameId = getGameIdFromProperty(trueProperty);
      await adjudicationContract.challenge(gameId, ["0x"], challengeGameId);
      await testPredicate.decideTrue(trueProperty.inputs);
      await expect(adjudicationContract.removeChallenge(gameId, challengeGameId))
        .to.be.reverted
    });
  });
});
