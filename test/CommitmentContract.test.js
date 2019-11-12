const chai = require('chai');
const {createMockProvider, deployContract, getWallets, solidity} = require('ethereum-waffle');
const CommitmentContract = require('../build/CommitmentContract');
const ethers = require('ethers');

chai.use(solidity);
chai.use(require('chai-as-promised'));
const {expect, assert} = chai;

describe('CommitmentContract', () => {
  let provider = createMockProvider();
  let wallets = getWallets(provider);
  let wallet = wallets[0];
  let commitmentContract;
  const root = ethers.utils.keccak256(ethers.utils.arrayify(ethers.constants.HashZero));

  beforeEach(async () => {
    commitmentContract = await deployContract(wallet, CommitmentContract, [wallet.address]);
  });

  describe('submitRoot', () => {
    it('succeed to submit root', async () => {
      await expect(commitmentContract.submitRoot(1, root))
        .to.emit(commitmentContract, 'BlockSubmitted')
    });
    it('fail to submit root because of unregistered operator address', async () => {
      const commitmentContractFromOtherWallet = commitmentContract.connect(wallets[1]);
      await expect(commitmentContractFromOtherWallet.submitRoot(1, root))
        .to.be.reverted;
    });
    it('fail to submit root because of invalid block number', async () => {
      await expect(commitmentContract.submitRoot(0, root))
        .to.be.reverted;
    });
  });

  describe('getCurrentBlock', () => {
    beforeEach(async () => {
      await expect(commitmentContract.submitRoot(1, root))
        .to.emit(commitmentContract, 'BlockSubmitted')
    });
  
    it('suceed to get current block', async () => {
      const currentBlock = await commitmentContract.currentBlock();
      expect(currentBlock).to.be.equal(1)
    });
  });

  describe('blocks', () => {
    beforeEach(async () => {
      await expect(commitmentContract.submitRoot(1, root))
        .to.emit(commitmentContract, 'BlockSubmitted')
    });
  
    it('suceed to get a block', async () => {
      const block = await commitmentContract.blocks(1);
      expect(block).to.be.equal(root)
    });
  });
});
