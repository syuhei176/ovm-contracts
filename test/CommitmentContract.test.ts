import chai from 'chai'
import {
  createMockProvider,
  deployContract,
  getWallets,
  solidity
} from 'ethereum-waffle'
import * as CommitmentContract from '../build/CommitmentContract.json'
import * as ethers from 'ethers'
import { Bytes } from 'wakkanay/dist/types/Codables'
import { Keccak256 } from 'wakkanay/dist/verifiers/hash/Keccak256'

chai.use(solidity)
chai.use(require('chai-as-promised'))
const { expect, assert } = chai

describe('CommitmentContract', () => {
  let provider = createMockProvider()
  let wallets = getWallets(provider)
  let wallet = wallets[0]
  let commitmentContract: any
  const root = ethers.utils.keccak256(
    ethers.utils.arrayify(ethers.constants.HashZero)
  )

  beforeEach(async () => {
    commitmentContract = await deployContract(wallet, CommitmentContract, [
      wallet.address
    ])
  })

  describe('submitRoot', () => {
    it('succeed to submit root', async () => {
      await expect(commitmentContract.submitRoot(1, root)).to.emit(
        commitmentContract,
        'BlockSubmitted'
      )
    })
    it('fail to submit root because of unregistered operator address', async () => {
      const commitmentContractFromOtherWallet = commitmentContract.connect(
        wallets[1]
      )
      await expect(commitmentContractFromOtherWallet.submitRoot(1, root)).to.be
        .reverted
    })
    it('fail to submit root because of invalid block number', async () => {
      await expect(commitmentContract.submitRoot(0, root)).to.be.reverted
    })
  })

  describe('verifyInclusion', () => {
    const tokenAddress = ethers.constants.AddressZero
    const leaf0 = {
      data: Keccak256.hash(Bytes.fromString('leaf0')),
      start: 0,
      address: tokenAddress
    }
    const leaf1 = {
      data: Keccak256.hash(Bytes.fromString('leaf1')),
      start: 7,
      address: tokenAddress
    }
    const blockNumber = 1
    const root =
      '0x1aa3429d5aa7bf693f3879fdfe0f1a979a4b49eaeca9638fea07ad7ee5f0b64f'
    const validInclusionProof = {
      addressInclusionProof: {
        leafPosition: 0,
        siblings: [
          {
            tokenAddress: '0x0000000000000000000000000000000000000001',
            data:
              '0xdd779be20b84ced84b7cbbdc8dc98d901ecd198642313d35d32775d75d916d3a'
          }
        ]
      },
      intervalInclusionProof: {
        leafPosition: 0,
        siblings: [
          {
            start: 7,
            data:
              '0x036491cc10808eeb0ff717314df6f19ba2e232d04d5f039f6fa382cae41641da'
          },
          {
            start: 5000,
            data:
              '0xef583c07cae62e3a002a9ad558064ae80db17162801132f9327e8bb6da16ea8a'
          }
        ]
      }
    }

    beforeEach(async () => {
      await commitmentContract.submitRoot(blockNumber, root)
    })

    it('suceed to verify inclusion', async () => {
      const result = await commitmentContract.verifyInclusion(
        leaf0.data,
        tokenAddress,
        { start: 0, end: 5 },
        validInclusionProof,
        blockNumber
      )
      expect(result).to.be.true
    })

    it('fail to verify inclusion because of invalid range', async () => {
      await expect(
        commitmentContract.verifyInclusion(
          leaf0.data,
          tokenAddress,
          { start: 10, end: 20 },
          validInclusionProof,
          blockNumber
        )
      ).to.be.revertedWith('_leftStart must be less than _rightStart')
    })

    it('fail to verify inclusion because of invalid hash data', async () => {
      const result = await commitmentContract.verifyInclusion(
        leaf1.data,
        tokenAddress,
        { start: 0, end: 5 },
        validInclusionProof,
        blockNumber
      )
      expect(result).to.be.false
    })

    it('fail to verify inclusion because of intersection', async () => {
      const invalidInclusionProof = {
        addressInclusionProof: {
          leafPosition: 0,
          siblings: [
            {
              tokenAddress: '0x0000000000000000000000000000000000000001',
              data:
                '0xdd779be20b84ced84b7cbbdc8dc98d901ecd198642313d35d32775d75d916d3a'
            }
          ]
        },
        intervalInclusionProof: {
          leafPosition: 0,
          siblings: [
            {
              start: 7,
              data:
                '0x036491cc10808eeb0ff717314df6f19ba2e232d04d5f039f6fa382cae41641da'
            },
            {
              start: 0,
              data:
                '0xef583c07cae62e3a002a9ad558064ae80db17162801132f9327e8bb6da16ea8a'
            }
          ]
        }
      }

      await expect(
        commitmentContract.verifyInclusion(
          leaf0.data,
          tokenAddress,
          { start: 0, end: 5 },
          invalidInclusionProof,
          blockNumber
        )
      ).to.be.revertedWith('_leftStart must be less than _rightStart')
    })

    it('fail to verify inclusion because of left.start is not less than right.start', async () => {
      const invalidInclusionProof = {
        addressInclusionProof: {
          leafPosition: 0,
          siblings: [
            {
              tokenAddress: '0x0000000000000000000000000000000000000001',
              data:
                '0xdd779be20b84ced84b7cbbdc8dc98d901ecd198642313d35d32775d75d916d3a'
            }
          ]
        },
        intervalInclusionProof: {
          leafPosition: 0,
          siblings: [
            {
              start: 0,
              data:
                '0x6fef85753a1881775100d9b0a36fd6c333db4e7f358b8413d3819b6246b66a30'
            },
            {
              start: 0,
              data:
                '0xef583c07cae62e3a002a9ad558064ae80db17162801132f9327e8bb6da16ea8a'
            }
          ]
        }
      }
      await expect(
        commitmentContract.verifyInclusion(
          leaf1.data,
          tokenAddress,
          { start: 7, end: 15 },
          invalidInclusionProof,
          blockNumber
        )
      ).to.be.revertedWith('_leftStart must be less than _rightStart')
    })
  })

  describe('getCurrentBlock', () => {
    beforeEach(async () => {
      await expect(commitmentContract.submitRoot(1, root)).to.emit(
        commitmentContract,
        'BlockSubmitted'
      )
    })

    it('suceed to get current block', async () => {
      const currentBlock = await commitmentContract.currentBlock()
      expect(currentBlock).to.be.equal(1)
    })
  })

  describe('blocks', () => {
    beforeEach(async () => {
      await expect(commitmentContract.submitRoot(1, root)).to.emit(
        commitmentContract,
        'BlockSubmitted'
      )
    })

    it('suceed to get a block', async () => {
      const block = await commitmentContract.blocks(1)
      expect(block).to.be.equal(root)
    })
  })
})
