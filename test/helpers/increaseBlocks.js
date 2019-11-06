const ethers = require('ethers');

async function increaseBlocks(wallets, num) {
  for(let i = 0;i < num;i++) {
    await increaseBlock(wallets)
  }
}

async function increaseBlock(wallets) {
  let tx = {
    to: wallets[1].address,
    value: ethers.utils.parseEther('0.0')
  };
  await wallets[0].sendTransaction(tx);
}

module.exports = {
  increaseBlocks
}
