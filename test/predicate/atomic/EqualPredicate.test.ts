import chai from 'chai'
import {
  createMockProvider,
  deployContract,
  getWallets,
  solidity
} from 'ethereum-waffle'
import * as MockAdjudicationContract from '../../../build/contracts/MockAdjudicationContract.json'
import * as Utils from '../../../build/contracts/Utils.json'
import * as EqualPredicate from '../../../build/contracts/EqualPredicate.json'
import * as ethers from 'ethers'

chai.use(solidity)
chai.use(require('chai-as-promised'))
const { expect, assert } = chai

describe('EqualPredicate', () => {
  let provider = createMockProvider()
  let wallets = getWallets(provider)
  let wallet = wallets[0]
  let equalPredicate: ethers.Contract
  let adjudicationContract: ethers.Contract

  beforeEach(async () => {
    const utils = await deployContract(wallet, Utils, [])
    adjudicationContract = await deployContract(
      wallet,
      MockAdjudicationContract,
      [utils.address]
    )
    equalPredicate = await deployContract(wallet, EqualPredicate, [
      adjudicationContract.address,
      utils.address
    ])
  })

  describe('decideTrue', () => {
    const input0 = '0x0000000011112222'
    const input1 = '0x0000000012345678'

    it('suceed to decide', async () => {
      await equalPredicate.decideTrue([input0, input0])
    })

    it('fail to decide', async () => {
      await expect(equalPredicate.decideTrue([input0, input1])).to.be.reverted
    })
  })
})
