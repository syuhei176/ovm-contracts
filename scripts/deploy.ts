/**
 * This deploy script was modified from https://github.com/plasma-group/pigi/blob/master/packages/unipig/src/contracts/deploy/deploy-rollup-chain.ts
 */
import { ethers } from 'ethers'
import { config } from 'dotenv'
import { resolve } from 'path'

import * as CommitmentContract from '../build/contracts/CommitmentContract.json'
import Provider = ethers.providers.Provider
import fs from 'fs'

if (
  !process.argv.length ||
  process.argv[process.argv.length - 1].endsWith('.js')
) {
  console.log('Error: Environment argument not provided.')
  process.exit(0)
}

const environment = process.argv[process.argv.length - 1]
const envPath = resolve(__dirname, `../../../.${environment}.env`)
if (!fs.existsSync(envPath)) {
  console.log(
    `Error: Environment argument not found. Please do 'cp .env.example .${environment}.env'`
  )
  process.exit(0)
}
config({ path: envPath })

const deployContract = async (
  contractJson: any,
  wallet: ethers.Wallet,
  ...args: any
): Promise<ethers.Contract> => {
  const factory = new ethers.ContractFactory(
    contractJson.abi,
    contractJson.bytecode,
    wallet
  )
  const contract = await factory.deploy(...args)
  console.log(
    `Address: [${contract.address}], Tx: [${contract.deployTransaction.hash}]`
  )
  return contract.deployed()
}

const deployContracts = async (wallet: ethers.Wallet): Promise<void> => {
  console.log('Deploying CommitmentContract')
  const operatorAddress = process.env.OPERATOR_ADDRESS
  if (operatorAddress === undefined) {
    throw new Error('OPERATOR_ADDRESS not provided.')
  }
  await deployContract(CommitmentContract, wallet, operatorAddress)
  console.log('CommitmentContract Deployed')
}

const deploy = async (): Promise<void> => {
  console.log(`\n\n********** STARTING DEPLOYMENT ***********\n\n`)
  // Make sure mnemonic exists
  const deployMnemonic = process.env.DEPLOY_MNEMONIC
  if (!deployMnemonic) {
    console.log(
      `Error: No DEPLOY_MNEMONIC env var set. Please add it to .<environment>.env file it and try again. See .env.example for more info.\n`
    )
    return
  }

  // Connect provider
  let provider: Provider
  const network = process.env.DEPLOY_NETWORK
  if (!network || network === 'local') {
    provider = new ethers.providers.JsonRpcProvider(
      process.env.DEPLOY_LOCAL_URL || 'http://127.0.0.1:8545'
    )
  } else {
    provider = ethers.getDefaultProvider(network)
  }

  // Create wallet
  const wallet = ethers.Wallet.fromMnemonic(deployMnemonic).connect(provider)

  console.log(`Deploying to network [${network || 'local'}] in 5 seconds!`)
  setTimeout(() => {
    deployContracts(wallet)
  }, 5_000)
}

deploy()
