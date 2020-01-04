import { ethers } from 'ethers'

export async function getTransactionEvent(
  provider: ethers.providers.Provider,
  tx: any,
  contract: ethers.Contract
) {
  await tx.wait()
  const receipt = await provider.getTransactionReceipt(tx.hash)
  const logs = receipt.logs || []
  return contract.interface.parseLog(logs[0])
}
