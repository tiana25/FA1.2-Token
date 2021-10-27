import { TezosToolkit } from '@taquito/taquito'
import { importKey } from '@taquito/signer'
const { Tezos } = require('@taquito/taquito')
const fs = require('fs')
const provider = 'https://florencenet.smartpy.io/'
async function deploy() {
  const tezos = new TezosToolkit(provider)
  await importKey(
    tezos,
    'ylmbozsf.uelknfhy@tezos.example.org', // пошта
    'ng2xd64OYP', // пароль
    [
      "equip",
      "tone",
      "book",
      "armor",
      "divorce",
      "phone",
      "scatter",
      "pigeon",
      "transfer",
      "family",
      "jump",
      "clutch",
      "mansion",
      "coyote",
      "issue"
    ].join(' '),
    'bd9c8382eaf2bfa62fe5f42ea55c14c768be9e63' //приватний ключ
  )
  try {
    const op = await tezos.contract.originate({
      // зчитуємо код з файлу token.json
      code: JSON.parse(fs.readFileSync('./ token.json').toString()),
      // задаємо стан сховища на мові Michelson. Замініть обидві адреси на адресу свого облікового запису в тестовій мережі,
      // а числа — на кількість токенів, яку ви хочете випустити
      init: '(Pair {Elt "tz1imn4fjJFwmNaiEWnAGdRrRHxzxrBdKafZ" (Pair {Elt "tz1imn4fjJFwmNaiEWnAGdRrRHxzxrBdKafZ" 1000} 1000)} 1000)',
    })
    // початок розгортання
    console.log('Awaiting confirmation ...')
    const contract = await op.contract()
    // звіт про розгортання: кількість використаного газу, значення сховища
    console.log('Gas Used', op.consumedGas)
    console.log('Storage', await contract.storage())
    // хеш операції, за яким можна знайти контракт в блокчейн-оглядачі
    console.log('Operation hash:', op.hash)
  } catch (ex) {
    console.error(ex)
  }
}
deploy()