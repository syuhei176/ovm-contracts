/* contract imports */
const chai = require('chai');
const {createMockProvider, deployContract, getWallets, solidity, link} = require('ethereum-waffle');
const UniversalAdjudicationContract = require('../build/UniversalAdjudicationContract');
const Utils = require('../build/Utils');
const NotPredicate = require('../build/NotPredicate');
const TestPredicate = require('../build/TestPredicate');
const ethers = require('ethers');
const abi = new ethers.utils.AbiCoder();

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
  let trueProperty, notProperty;

  before(async () => {
    utils = await deployContract(wallet, Utils, []);
    link(UniversalAdjudicationContract, 'contracts/Utils.sol:Utils', utils.address);
  });

  beforeEach(async () => {
    adjudicationContract = await deployContract(wallet, UniversalAdjudicationContract);
    notPredicate = await deployContract(wallet, NotPredicate, [adjudicationContract.address]);
    testPredicate = await deployContract(wallet, TestPredicate, [adjudicationContract.address]);
    trueProperty = {
      predicateAddress: testPredicate.address,
      inputs: ['0x01']
    };
    notProperty = {
      predicateAddress: notPredicate.address,
      inputs: [abi.encode(['tuple(address, bytes[])'], [[testPredicate.address, ['0x01']]])]
    };
  });

  describe('claimProperty', () => {
    it('adds a claim', async () => {
      await adjudicationContract.claimProperty(notProperty);
      const claimId = await adjudicationContract.getPropertyId(notProperty);
      const game = await adjudicationContract.getGame(claimId);

      // check newly stored property is equal to the claimed property
      assert.equal(game.property.predicateAddress, notProperty.predicateAddress);
      assert.equal(game.property.input, notProperty.input);
    });
    it('fails to add an already claimed property and throws Error', async () => {
      // claim a property
      await adjudicationContract.claimProperty(trueProperty);
      // check if the second call of the claimProperty function throws an error
      assert(await expect(adjudicationContract.claimProperty(trueProperty)).to.be.rejectedWith(Error));
    });
  });

  describe('challenge', () => {
    it('challenge', async () => {
      await adjudicationContract.claimProperty(notProperty);
      await adjudicationContract.claimProperty(trueProperty);
      const gameId = await adjudicationContract.getPropertyId(notProperty);
      const challengingGameId = await adjudicationContract.getPropertyId(trueProperty);
      await adjudicationContract.challenge(gameId, ["0x"], challengingGameId);
      const game = await adjudicationContract.getGame(gameId);

      assert.equal(game.challenges.length, 1);
    });
  });

  describe('decideClaimToFalse', () => {
    it('game should be decided false', async () => {
      await adjudicationContract.claimProperty(notProperty);
      await adjudicationContract.claimProperty(trueProperty);
      const gameId = await adjudicationContract.getPropertyId(notProperty);
      const challengingGameId = await adjudicationContract.getPropertyId(trueProperty);
      await adjudicationContract.challenge(gameId, ["0x"], challengingGameId);
      await testPredicate.decideTrue(['0x01'], '0x');
      await adjudicationContract.decideClaimToFalse(gameId, challengingGameId);
      const game = await adjudicationContract.getGame(gameId);
      // game should be decided false
      assert.equal(game.decision, 2);
    });
  });

  describe('decideClaimToTrue', () => {
    it('game should be decided true', async () => {
      await adjudicationContract.claimProperty(notProperty);
      const gameId = await adjudicationContract.getPropertyId(notProperty);
      // increase 10 blocks to pass dispute period
      await increaseBlocks(wallets, 10);
      await adjudicationContract.decideClaimToTrue(gameId);

      const game = await adjudicationContract.getGame(gameId);
      // game should be decided true
      assert.equal(game.decision, 1);
    });
    it('fail to decided true because dispute period has not passed', async () => {
      await adjudicationContract.claimProperty(notProperty);
      const gameId = await adjudicationContract.getPropertyId(notProperty);
      await expect(adjudicationContract.decideClaimToTrue(gameId)).to.be.reverted;
    });
  });
});

async function increaseBlocks(wallets, num) {
  for(let i = 0;i < num;i++) {
    await increaseBlock(wallets)
  }
}

async function increaseBlock(wallets) {
  let tx = {
    to: wallets[1].address,
    value: ethers.utils.parseEther('0.0')
  };
  await wallets[0].sendTransaction(tx);
}
