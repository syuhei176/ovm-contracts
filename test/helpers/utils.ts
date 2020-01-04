import {
  arrayify,
  concat,
  hexlify,
  keccak256,
  padZeros,
  randomBytes,
  toUtf8Bytes,
  AbiCoder
} from 'ethers/utils'
const abi = new AbiCoder()

export interface OvmProperty {
  predicateAddress: string
  inputs: string[]
}

export function getGameIdFromProperty(ovmProperty: OvmProperty) {
  return keccak256(
    abi.encode(
      ['tuple(address, bytes[])'],
      [[ovmProperty.predicateAddress, ovmProperty.inputs]]
    )
  )
}

function numberToHex(n: number) {
  const h = n.toString(16)
  if (h.length % 2 == 1) {
    return '0x0' + h
  } else {
    return '0x' + h
  }
}

function numberTo32Bytes(n: number) {
  return padZeros(arrayify(numberToHex(n)), 32)
}

function concatHex(hexArr: string[]): string {
  return hexlify(concat(hexArr.map(arrayify)))
}

export function prefix(_prefix: string, _source: string): string {
  return concatHex([hexlify(toUtf8Bytes(_prefix)), _source])
}

export function encodeRange(start: number, end: number) {
  return hexlify(concat([numberTo32Bytes(start), numberTo32Bytes(end)]))
}

export function encodeInteger(int: number) {
  return hexlify(numberTo32Bytes(int))
}

export function encodeProperty(property: OvmProperty) {
  return abi.encode(
    ['tuple(address, bytes[])'],
    [[property.predicateAddress, property.inputs]]
  )
}

export function encodeString(str: string) {
  return hexlify(toUtf8Bytes(str))
}

export function encodeLabel(str: string) {
  return prefix('L', encodeString(str))
}

export function encodeVariable(str: string) {
  return prefix('V', encodeString(str))
}

export function encodeConstant(str: string) {
  return prefix('C', encodeString(str))
}

export function encodeAddress(address: string) {
  return hexlify(padZeros(arrayify(address), 32))
}

export function randomAddress() {
  return hexlify(randomBytes(20))
}
