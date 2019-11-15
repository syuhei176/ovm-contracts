import * as ethers from 'ethers'

export async function increaseBlocks(wallets: ethers.Wallet[], num: number) {
  for (let i = 0; i < num; i++) {
    await increaseBlock(wallets)
  }
}

async function increaseBlock(wallets: ethers.Wallet[]) {
  let tx = {
    to: wallets[1].address,
    value: ethers.utils.parseEther('0.0')
  }
  await wallets[0].sendTransaction(tx)
}
