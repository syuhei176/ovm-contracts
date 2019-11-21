import chai from 'chai'
import {
  createMockProvider,
  deployContract,
  getWallets,
  solidity
} from 'ethereum-waffle'
import * as MockAdjudicationContract from '../../../build/MockAdjudicationContract.json'
import * as Utils from '../../../build/Utils.json'
import * as IsValidSignaturePredicate from '../../../build/IsValidSignaturePredicate.json'
import * as ethers from 'ethers'
import { hexlify, toUtf8Bytes } from 'ethers/utils'

chai.use(solidity)
chai.use(require('chai-as-promised'))
const { expect, assert } = chai

describe('IsValidSignaturePredicate', () => {
  let provider = createMockProvider()
  let wallets = getWallets(provider)
  let wallet = wallets[0]
  let utils
  let isValidSignaturePredicate: ethers.Contract
  let adjudicationContract: ethers.Contract

  beforeEach(async () => {
    utils = await deployContract(wallet, Utils, [])
    adjudicationContract = await deployContract(
      wallet,
      MockAdjudicationContract,
      [utils.address]
    )
    isValidSignaturePredicate = await deployContract(
      wallet,
      IsValidSignaturePredicate,
      [adjudicationContract.address, utils.address]
    )
  })

  describe('decideTrue', () => {
    const verifierType = ethers.utils.toUtf8Bytes('secp256k1')
    const address = '0xa7E678F5F3Db99bf4957AC2ebEb3a89C6f9031F6'
    const signature =
      '0x3050ed8255d5599ebce4be5ef23eceeb61bfae924db5e5b12fc975663854629204a68351940fcea4231e9e4af515e2a10c187fcd7f88f4e5ffed218c76a5553b1b'
    const invalidSignature =
      '0x00b0ed8255d5599ebce4be5ef23eceeb16bfae924db5e5b12fc975663854629204a68351940fcea4231e9e4af515e2a10c187fcd7f88f4e5ffed218c76a1113bb2'

    const message = hexlify(toUtf8Bytes('message'))
    it('suceed to decide', async () => {
      await isValidSignaturePredicate.decideTrue([
        message,
        signature,
        address,
        verifierType
      ])
    })
    it('fail to decide with invalid signature', async () => {
      await expect(
        isValidSignaturePredicate.decideTrue([
          message,
          invalidSignature,
          address,
          verifierType
        ])
      ).to.be.reverted
    })
    it('fail to decide with empty signature', async () => {
      await expect(
        isValidSignaturePredicate.decideTrue([
          message,
          '0x',
          address,
          verifierType
        ])
      ).to.be.reverted
    })
  })
})
