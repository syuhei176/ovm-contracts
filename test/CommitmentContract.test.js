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

  beforeEach(async () => {
    commitmentContract = await deployContract(wallet, CommitmentContract, [wallet.address]);
  });

  describe('submitRoot', () => {
    const root = ethers.utils.keccak256(ethers.utils.arrayify(ethers.constants.HashZero));
    it('succeed to submit root', async () => {
      await expect(commitmentContract.submitRoot(1, root))
        .to.emit(commitmentContract, 'BlockSubmitted')
    });
    it('fail to submit root because unregistered operator address', async () => {
      const commitmentContractFromOtherWallet = commitmentContract.connect(wallets[1]);
      await expect(commitmentContractFromOtherWallet.submitRoot(1, root))
        .to.be.reverted;
    });
    it('fail to submit root because invalid block number', async () => {
      await expect(commitmentContract.submitRoot(0, root))
        .to.be.reverted;
    });
  });
});
