// імпортуємо Tx.ts
import { Tx } from './tx'
// міняємо RPC-посилання з мейннета на тестову мережу. Не лякайтеся smartpy в посиланні — це просто адреса сервера
const RPC_URL = 'https://florencenet.smartpy.io/'
const ADDRESS = 'tz1aRoaRhSpRYvFdyvgWLL6TGyRoGF51wDjM'
// викликаємо функцію Tx, передаємо їй посилання на тестову мережу і просимо активувати обліковий запис
new Tx(RPC_URL).activateAccount()