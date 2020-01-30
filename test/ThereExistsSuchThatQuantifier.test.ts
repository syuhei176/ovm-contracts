/* contract imports */
import chai from 'chai'
import {
  createMockProvider,
  deployContract,
  getWallets,
  solidity
} from 'ethereum-waffle'
import * as MockChallenge from '../build/contracts/MockChallenge.json'
import * as ThereExistsSuchThatQuantifier from '../build/contracts/ThereExistsSuchThatQuantifier.json'
import * as ethers from 'ethers'
import {
  OvmProperty,
  randomAddress,
  encodeProperty,
  encodeString
} from './helpers/utils'

chai.use(solidity)
chai.use(require('chai-as-promised'))
const { expect, assert } = chai

describe('ThereExistsSuchThatQuantifier', () => {
  let provider = createMockProvider()
  let wallets = getWallets(provider)
  let wallet = wallets[0]
  let thereExistsSuchThatQuantifier: ethers.Contract
  const boolAddress = randomAddress()
  const notAddress = randomAddress()
  const forAddress = randomAddress()
  let mockChallenge: ethers.Contract
  let thereProperty: OvmProperty

  beforeEach(async () => {
    mockChallenge = await deployContract(wallet, MockChallenge, [])
    thereExistsSuchThatQuantifier = await deployContract(
      wallet,
      ThereExistsSuchThatQuantifier,
      [notAddress, forAddress]
    )
    thereProperty = {
      predicateAddress: thereExistsSuchThatQuantifier.address,
      inputs: [
        encodeString(''),
        encodeString('var'),
        encodeProperty({
          predicateAddress: boolAddress,
          inputs: ['0x01']
        })
      ]
    }
  })

  describe('isValidChallenge', () => {
    it('suceed to challenge any(a) with for(not(a))', async () => {
      const challengeProperty = {
        predicateAddress: forAddress,
        inputs: [
          encodeString(''),
          encodeString('var'),
          encodeProperty({
            predicateAddress: notAddress,
            inputs: [
              encodeProperty({
                predicateAddress: boolAddress,
                inputs: ['0x01']
              })
            ]
          })
        ]
      }
      const result = await mockChallenge.isValidChallenge(
        thereProperty,
        [],
        challengeProperty
      )
      assert.isTrue(result)
    })
    it('fail to challenge with invalid variable', async () => {
      const challengeProperty = {
        predicateAddress: forAddress,
        inputs: [
          encodeString(''),
          encodeString('invalid'),
          encodeProperty({
            predicateAddress: notAddress,
            inputs: [
              encodeProperty({
                predicateAddress: boolAddress,
                inputs: ['0x01']
              })
            ]
          })
        ]
      }
      await expect(
        mockChallenge.isValidChallenge(thereProperty, [], challengeProperty)
      ).to.be.revertedWith('variable must be same')
    })
    it('fail to challenge with invalid property', async () => {
      const challengeProperty = {
        predicateAddress: forAddress,
        inputs: [
          encodeString(''),
          encodeString('var'),
          encodeProperty({
            predicateAddress: notAddress,
            inputs: [
              encodeProperty({
                predicateAddress: boolAddress,
                inputs: ['0x02']
              })
            ]
          })
        ]
      }
      await expect(
        mockChallenge.isValidChallenge(thereProperty, [], challengeProperty)
      ).to.be.revertedWith('inputs must be same')
    })
  })
})
