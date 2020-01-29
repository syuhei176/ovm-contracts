import { generateEVMByteCode } from '@cryptoeconomicslab/ovm-ethereum-generator'
import { Import } from '@cryptoeconomicslab/ovm-parser'
import fs from 'fs'
import path from 'path'

compileAllSourceFiles(
  path.join(__dirname, '../../../contracts/Predicate/plasma')
).then(() => {
  console.log('all compiled')
})

async function compileAllSourceFiles(targetDir: string) {
  const files = fs.readdirSync(targetDir)

  await Promise.all(
    files
      .map(f => {
        const ext = path.extname(f)
        if (ext == '.ovm') {
          return compile(targetDir, path.basename(f, ext))
        }
      })
      .filter(p => !!p)
  )
}

async function compile(basePath: string, contractName: string) {
  const source = fs
    .readFileSync(path.join(basePath, contractName + '.ovm'))
    .toString()
  const output = await generateEVMByteCode(source, (_import: Import) => {
    return fs
      .readFileSync(path.join(basePath, _import.path, _import.module + '.ovm'))
      .toString()
  })
  fs.writeFileSync(
    path.join(__dirname, `../../../build/contracts/${contractName}.json`),
    output
  )
}
