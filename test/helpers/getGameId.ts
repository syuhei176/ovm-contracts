import * as ethers from 'ethers'
const abi = new ethers.utils.AbiCoder()

export interface OvmProperty {
  predicateAddress: string
  inputs: string[]
}

export function getGameIdFromProperty(ovmProperty: OvmProperty) {
  return ethers.utils.keccak256(
    abi.encode(
      ['tuple(address, bytes[])'],
      [[ovmProperty.predicateAddress, ovmProperty.inputs]]
    )
  )
}
