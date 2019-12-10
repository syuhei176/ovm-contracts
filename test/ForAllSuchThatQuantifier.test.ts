import chai from 'chai'
import {
  createMockProvider,
  deployContract,
  getWallets,
  solidity
} from 'ethereum-waffle'
import * as Utils from '../build/Utils.json'
import * as MockAdjudicationContract from '../build/MockAdjudicationContract.json'
import * as MockChallenge from '../build/MockChallenge.json'
import * as ForAllSuchThatQuantifier from '../build/ForAllSuchThatQuantifier.json'
import * as AndPredicate from '../build/AndPredicate.json'
import * as NotPredicate from '../build/NotPredicate.json'
import * as TestPredicate from '../build/TestPredicate.json'
import * as ethers from 'ethers'
const abi = new ethers.utils.AbiCoder()
import { getGameIdFromProperty, OvmProperty } from './helpers/getGameId'
import { FreeVariable } from 'wakkanay/dist/ovm/types'
chai.use(solidity)
chai.use(require('chai-as-promised'))
const { expect, assert } = chai

describe('ForAllSuchThatQuantifier', () => {
  let provider = createMockProvider()
  let wallets = getWallets(provider)
  let wallet = wallets[0]
  let utils
  let testPredicate: ethers.Contract
  let andPredicate: ethers.Contract
  let forAllSuchThatQuantifier: ethers.Contract
  let notPredicate: ethers.Contract
  let adjudicationContract: ethers.Contract
  let mockChallenge: ethers.Contract
  let trueProperty: OvmProperty,
    notTrueProperty: OvmProperty,
    forAllSuchThatProperty: OvmProperty

  const createPlaceholder = (name: string) => {
    return ethers.utils.hexlify(ethers.utils.toUtf8Bytes(name))
  }

  beforeEach(async () => {
    mockChallenge = await deployContract(wallet, MockChallenge, [])
    utils = await deployContract(wallet, Utils, [])
    adjudicationContract = await deployContract(
      wallet,
      MockAdjudicationContract,
      [utils.address]
    )
    notPredicate = await deployContract(wallet, NotPredicate, [
      adjudicationContract.address,
      utils.address
    ])
    andPredicate = await deployContract(wallet, AndPredicate, [
      adjudicationContract.address,
      notPredicate.address,
      utils.address
    ])
    forAllSuchThatQuantifier = await deployContract(
      wallet,
      ForAllSuchThatQuantifier,
      [
        adjudicationContract.address,
        notPredicate.address,
        andPredicate.address,
        utils.address
      ]
    )
    testPredicate = await deployContract(wallet, TestPredicate, [
      adjudicationContract.address,
      utils.address
    ])
    trueProperty = {
      predicateAddress: testPredicate.address,
      inputs: ['0x01']
    }
    notTrueProperty = {
      predicateAddress: notPredicate.address,
      inputs: [
        abi.encode(
          ['tuple(address, bytes[])'],
          [[testPredicate.address, ['0x01']]]
        )
      ]
    }
    forAllSuchThatProperty = {
      predicateAddress: forAllSuchThatQuantifier.address,
      inputs: [
        abi.encode(['tuple(address, bytes[])'], [[testPredicate.address, []]]),
        createPlaceholder('n'),
        abi.encode(
          ['tuple(address, bytes[])'],
          [[testPredicate.address, [FreeVariable.from('n').toHexString()]]]
        )
      ]
    }
  })

  describe('isValidChallenge', () => {
    it('validate challenge with not(test(0x01)) to for all t such that Test(t)', async () => {
      const challengeInput = '0x01'
      const result = await mockChallenge.isValidChallenge(
        forAllSuchThatProperty,
        challengeInput,
        notTrueProperty
      )
      assert.isTrue(result)
    })
    it('fail to validate challenge with test(0x01) to for all t such that Test(t)', async () => {
      const challengeInput = '0x01'
      await expect(
        mockChallenge.isValidChallenge(
          forAllSuchThatProperty,
          challengeInput,
          trueProperty
        )
      ).to.be.reverted
    })
  })

  describe('set property as variable', () => {
    it('for all property such that: property()', async () => {
      const challengeInput = abi.encode(
        ['tuple(address, bytes[])'],
        [[testPredicate.address, ['0x01']]]
      )
      const forAllSuchThatProperty = {
        predicateAddress: forAllSuchThatQuantifier.address,
        inputs: [
          '0x',
          createPlaceholder('n'),
          FreeVariable.from('n').toHexString()
        ]
      }
      mockChallenge.isValidChallenge(
        forAllSuchThatProperty,
        challengeInput,
        notTrueProperty
      )
    })
  })
})
