/* contract imports */
const chai = require('chai');
const {createMockProvider, deployContract, getWallets, solidity, link} = require('ethereum-waffle');
const UniversalAdjudicationContract = require('../build/UniversalAdjudicationContract');
const Utils = require('../build/Utils');
const TestPredicate = require('../build/TestPredicate');
const ethers =require('ethers');
const abi = new ethers.utils.AbiCoder()

chai.use(solidity);
chai.use(require('chai-as-promised'));
const {expect, assert} = chai;

describe('UniversalAdjudicationContract', () => {
  let provider = createMockProvider();
  let wallets = getWallets(provider);
  let wallet = wallets[0];
  let adjudicationContract;
  let utils;
  let testPredicate;

  before(async () => {
    utils = await deployContract(wallet, Utils, []);
    link(UniversalAdjudicationContract, 'contracts/Utils.sol:Utils', utils.address);
  });

  beforeEach(async () => {
    adjudicationContract = await deployContract(wallet, UniversalAdjudicationContract);
    testPredicate = await deployContract(wallet, TestPredicate, [adjudicationContract.address]);
  });

  describe('claimProperty', () => {
    it('adds a claim', async () => {
      const property = [testPredicate.address, '0x01'];
      const encoded = abi.encode(['address', 'bytes'], property);

      await adjudicationContract.claimProperty(encoded);
      const claimId = await adjudicationContract.getPropertyId(property);
      const claim = await adjudicationContract.getClaim(claimId);

      // check newly stored property is equal to the claimed property
      assert.equal(claim.predicateAddress, property[0]);
      assert.equal(claim.input, property[1]);
    });
    it('fails to add an already claimed property and throws Error', async () => {
      const property = [testPredicate.address, '0x01'];
      const encoded = abi.encode(['address', 'bytes'], property);
      // claim a property
      await adjudicationContract.claimProperty(encoded);
      // check if the second call of the claimProperty function throws an error
      assert(await expect(adjudicationContract.claimProperty(encoded)).to.be.rejectedWith(Error));
    });
  });

  describe('decideProperty', () => {
    it('approve a claim when decision is true', async () => {
      const testPredicateInput = {
        value: 1
      };
      const property = await testPredicate.createPropertyFromInput(testPredicateInput);
      await testPredicate.decideTrue(testPredicateInput);
      const decidedPropertyId = await adjudicationContract.getPropertyId(property);
      const blockNumber = await provider.getBlockNumber()
      const decidedClaim = await adjudicationContract.claims(decidedPropertyId);

      //check the block number of newly decided property is equal to the claimed property's
      assert.equal(decidedClaim.decidedAfter, blockNumber - 1);
    });

    it('deletes a claim when the decision is false', async () => {
      const testPredicateInput = {
        value: 1
      };
      const property = await testPredicate.createPropertyFromInput(testPredicateInput);
      await testPredicate.decideFalse(testPredicateInput);
      const falsifiedPropertyId = await adjudicationContract.getPropertyId(property);
      const falsifiedClaim = await adjudicationContract.claims(falsifiedPropertyId);

      // check the claimed property is deleted
      assert(isEmptyClaimStatus(falsifiedClaim));
    })
  });
});

function isEmptyClaimStatus(_claimStatus) {
  return ethers.utils.bigNumberify(_claimStatus.property.predicateAddress).isZero()
    && ethers.utils.arrayify(_claimStatus.property.input).length === 0
    && _claimStatus.decidedAfter.isZero()
    && _claimStatus.numProvenContradictions.isZero()
}
