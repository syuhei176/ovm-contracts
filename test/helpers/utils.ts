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

export function encodeProperty(property: OvmProperty) {
  return abi.encode(
    ['tuple(address, bytes[])'],
    [[property.predicateAddress, property.inputs]]
  )
}

export function encodeString(str: string) {
  return ethers.utils.hexlify(ethers.utils.toUtf8Bytes(str))
}

export function randomAddress() {
  return ethers.utils.hexlify(ethers.utils.randomBytes(20))
}
