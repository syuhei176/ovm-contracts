/* contract imports */
import chai from 'chai'
import {
  createMockProvider,
  deployContract,
  getWallets,
  solidity,
  link
} from 'ethereum-waffle'
import * as UniversalAdjudicationContract from '../build/UniversalAdjudicationContract.json'
import * as Utils from '../build/Utils.json'
import * as AndPredicate from '../build/AndPredicate.json'
import * as NotPredicate from '../build/NotPredicate.json'
import * as TestPredicate from '../build/TestPredicate.json'
import * as ethers from 'ethers'
const abi = new ethers.utils.AbiCoder()
import { getGameIdFromProperty, OvmProperty } from './helpers/getGameId'

chai.use(solidity)
chai.use(require('chai-as-promised'))
const { expect, assert } = chai

describe('AndPredicate', () => {
  let provider = createMockProvider()
  let wallets = getWallets(provider)
  let wallet = wallets[0]
  let utils
  let testPredicate, andPredicate, notPredicate
  let adjudicationContract: any
  let trueProperty: OvmProperty,
    andProperty: OvmProperty,
    notTrueProperty: OvmProperty,
    notFalseProperty: OvmProperty

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
    testPredicate = await deployContract(wallet, TestPredicate, [
      adjudicationContract.address,
      utils.address
    ])
    trueProperty = {
      predicateAddress: testPredicate.address,
      inputs: ['0x01']
    }
    andProperty = {
      predicateAddress: andPredicate.address,
      inputs: [
        abi.encode(
          ['tuple(address, bytes[])'],
          [[testPredicate.address, ['0x01']]]
        ),
        abi.encode(['tuple(address, bytes[])'], [[testPredicate.address, []]])
      ]
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
    notFalseProperty = {
      predicateAddress: notPredicate.address,
      inputs: [
        abi.encode(['tuple(address, bytes[])'], [[testPredicate.address, []]])
      ]
    }
  })

  describe('isValidChallenge', () => {
    it('suceed to challenge and(t, f) with not(t)', async () => {
      const challengeInput = abi.encode(['uint256'], [0])
      await adjudicationContract.claimProperty(andProperty)
      await adjudicationContract.claimProperty(notTrueProperty)
      const gameId = getGameIdFromProperty(andProperty)
      const challengingGameId = getGameIdFromProperty(notTrueProperty)
      await adjudicationContract.challenge(
        gameId,
        [challengeInput],
        challengingGameId
      )
      const game = await adjudicationContract.getGame(gameId)
      assert.equal(game.challenges.length, 1)
    })
    it('suceed to challenge and(t, f) with not(f)', async () => {
      const challengeInput = abi.encode(['uint256'], [1])
      await adjudicationContract.claimProperty(andProperty)
      await adjudicationContract.claimProperty(notFalseProperty)
      const gameId = getGameIdFromProperty(andProperty)
      const challengingGameId = getGameIdFromProperty(notFalseProperty)
      await adjudicationContract.challenge(
        gameId,
        [challengeInput],
        challengingGameId
      )
      const game = await adjudicationContract.getGame(gameId)
      assert.equal(game.challenges.length, 1)
    })
    it('fail to challenge and(t, f) with t', async () => {
      const challengeInput = abi.encode(['uint256'], [1])
      await adjudicationContract.claimProperty(andProperty)
      await adjudicationContract.claimProperty(trueProperty)
      const gameId = getGameIdFromProperty(andProperty)
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
