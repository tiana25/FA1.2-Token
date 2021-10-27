import { TezosToolkit } from '@taquito/taquito'
//імпортуємо inMemorySigner. Він збереже приватний ключ в оперативній пам'яті і буде підписувати ним транзакції
import { InMemorySigner } from '@taquito/signer'
//оголошуємо константу acc, яка направить скрипт до файлу acc.json
const acc = require('./acc.json')
export class Tx {
  private tezos: TezosToolkit
  rpcUrl: string
  constructor(rpcUrl: string) {
    this.tezos = new TezosToolkit(rpcUrl)
    this.rpcUrl = rpcUrl

    //оголошуємо параметри за допомогою методу fromFundraiser: пошту, пароль і мнемонічну фразу, з якої можна отримати приватний ключ
    this.tezos.setSignerProvider(InMemorySigner.fromFundraiser(acc.email, acc.password, acc.mnemonic.join('')))
  }
  // отримуємо публічний і приватний ключі і активуємо аккаунт
  public async activateAccount() {
    const { pkh, secret } = acc
    try {
      const operation = await this.tezos.tz.activate(pkh, secret)
      await operation.confirmation()
    } catch (e) {
      console.log(e)
    }
  }
  public async main() {}
}