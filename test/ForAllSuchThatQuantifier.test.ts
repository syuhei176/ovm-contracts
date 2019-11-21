import chai from 'chai'
import {
  createMockProvider,
  deployContract,
  getWallets,
  solidity
} from 'ethereum-waffle'
import * as Utils from '../build/Utils.json'
import * as UniversalAdjudicationContract from '../build/UniversalAdjudicationContract.json'
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
  let trueProperty: OvmProperty,
    notTrueProperty: OvmProperty,
    forAllSuchThatProperty: OvmProperty

  beforeEach(async () => {
    utils = await deployContract(wallet, Utils, [])
    adjudicationContract = await deployContract(
      wallet,
      UniversalAdjudicationContract,
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
        ethers.utils.hexlify(ethers.utils.toUtf8Bytes('n')),
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
      await adjudicationContract.claimProperty(forAllSuchThatProperty)
      await adjudicationContract.claimProperty(notTrueProperty)
      const gameId = getGameIdFromProperty(forAllSuchThatProperty)
      const challengingGameId = getGameIdFromProperty(notTrueProperty)
      await adjudicationContract.challenge(
        gameId,
        [challengeInput],
        challengingGameId
      )
      const game = await adjudicationContract.getGame(gameId)
      assert.equal(game.challenges.length, 1)
    })
    it('fail to validate challenge with test(0x01) to for all t such that Test(t)', async () => {
      const challengeInput = '0x01'
      await adjudicationContract.claimProperty(forAllSuchThatProperty)
      await adjudicationContract.claimProperty(trueProperty)
      const gameId = getGameIdFromProperty(forAllSuchThatProperty)
      const challengingGameId = getGameIdFromProperty(trueProperty)
      await expect(
        adjudicationContract.challenge(
          gameId,
          [challengeInput],
          challengingGameId
        )
      ).to.be.reverted
    })
  })
})
