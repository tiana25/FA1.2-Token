import { TezosToolkit } from '@taquito/taquito'
export class App {
  private tezos: TezosToolkit
  constructor(rpcUrl: string) {
    this.tezos = new TezosToolkit(rpcUrl)
  }
  //оголошуємо метод getBalance з вхідним параметром address
  public getBalance(address: string): void {
    //Taquito відправляє вузлу запит балансу зазначеної адреси. Якщо вузол виконав запит, скрипт виводить отримане значення в консоль. Якщо сталася помилка — видає «Address not found»
    this.tezos.rpc
      .getBalance(address)
      .then((balance) => console.log(balance))
      .catch((e) => console.log('Address not found'))
  }
  public async main() {}
}