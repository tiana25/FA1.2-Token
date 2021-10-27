//оголошуємо псевдонім trusted типу address. Ми будемо використовувати його для позначення адрес, у яких є право відправляти токени
type trusted is address;
// оголошуємо псевдонім amt (amount) типу nat для зберігання балансів
type amt is nat;
(* Оголошуємо псевдонім account типу record. У ньому будемо зберігати дані користувачів, яким можна передавати токени.
*)
type account is
 record [
   balance: amt;
   allowances: map (trusted, amt);
 ]
(* Оголошуємо тип сховища смарт-контракту. В ньому зберігається загальна кількість токенів, а також структура даних big_map, яка пов'язує публічні адреси і баланси користувачів *)
type storage is
 record [
   totalSupply: amt;
   ledger: big_map (address, account);
 ]
(* Оголошуємо псевдонім для методу return, який будемо використовувати для повернення операцій. У коротких контрактах можна обійтися без нього, але в контрактах з декількома псевдо-точками входу простіше один раз прописати тип повернення і використовувати його в кожній функції *)
type return is list (operation) * storage
(* Оголошуємо порожній список noOperations. Його повертатимуть функції transfer і approve *)
const noOperations: list (operation) = nil;


(* Оголошуємо псевдоніми вхідних параметрів для кожної базової функції FA 1.2. *)
// функція transfer отримує на вхід адресу відправника, адресу одержувача і суму транзакції
type transferParams is michelson_pair (address, "from", michelson_pair (address, "to", amt, "value"), "")
// approve отримує адресу користувача і кількість токенів, які він може відправити з балансу смарт-контракту
type approveParams is michelson_pair (trusted, "spender", amt, "value")
// getBallance отримує адресу користувача і проксі-контракту, яким вона відправить дані про баланс
type balanceParams is michelson_pair (address, "owner", contract (amt), "")
// getAllowance отримує адресу користувача, дані його аккаунта в смарт-контракті і проксі-контракт
type allowanceParams is michelson_pair (michelson_pair (address, "owner", trusted, "spender"), "", contract (amt), "")
// totalSupply не використовує michelson_pair, тому що перший вхідний параметр — пусте значення unit — і так виявиться першим після сортування компілятора Michelson
type totalSupplyParams is (unit * contract (amt))
(* Оголошуємо псевдо-точки входу: даємо назву і присвоюємо їм тип параметрів, які описали вище *)
type entryAction is
 | Transfer of transferParams
 | Approve of approveParams
 | GetBalance of balanceParams
 | GetAllowance of allowanceParams
 | GetTotalSupply of totalSupplyParams

function getAccount (const addr: address; const s: storage): account is
 block {
     // присвоюємо змінної acct значення типу account: нульовий баланс і порожній запис allowances
   var acct : account :=
     record [
       balance = 0n;
       allowances = (map []: map (address, amt));
     ];
   (* Перевіряємо, чи є в сховищі аккаунт користувача. Якщо немає — залишаємо в acct пусте значення з попереднього блоку. Якщо є — присвоюємо змінній acct значення зі сховища. Функція повертає значення acct *)
   case s.ledger [addr] of
     None -> skip
   | Some (instance) -> acct:= instance
   end;
 } with acct

function getAllowance (const ownerAccount: account; const spender: address; const s: storage): amt is
 (* Якщо користувач дозволив відправити кілька токенів, функція присвоює це кількість змінної amt. Якщо не дозволив — кількість токенів дорівнює нулю *)
 case ownerAccount.allowances [spender] of
   Some (amt) -> amt
 | None -> 0n
 end;

function transfer (const from_: address; const to_: address; const value: amt; var s: storage): return is
 block {
   (* Викликаємо функцію getAccount, щоб привласнити змінній senderAccount дані облікового запису користувача. Потім ми використовуємо senderAccount, щоб зчитувати баланс користувача і дозволи *)
   var senderAccount: account:= getAccount (from_, s);
   (* Перевіряємо, чи достатньо у користувача засобів для переказу. Якщо ні — віртуальна машина перериває виконання контракту, якщо достатньо — продовжує виконувати контракт *)
   if senderAccount.balance < value then
     failwith ( "NotEnoughBalance")
   else skip;
   (* Перевіряємо, чи може адрес-ініціатор транзакції відправити токени. Якщо він запитує переказ з чужої адреси, функція запитує дозвіл у справжнього власника. Якщо ініціатор і відправник — одна адреса, віртуальна машина продовжує виконувати контракт *)
   if from_ =/= Tezos.sender then block {
   (* Викликаємо функцію getAllowance, щоб власник адреси-відправника вказав, скільки токенів він дозволяє відправити. Надаємо це значення константі spenderAllowance *)
     const spenderAllowance: amt = getAllowance (senderAccount, Tezos.sender, s);
   (* Якщо власник дозволив відправити менше токенів, ніж зазначено у вхідному параметрі, віртуальна машина припинить виконувати контракт *)
     if spenderAllowance <value then
       failwith ( "NotEnoughAllowance")
     else skip;
     (* Віднімаємо від дозволеної для переказу кількості токенів суму транзакції *)
     senderAccount.allowances [Tezos.sender]:= abs (spenderAllowance - value);
   } else skip;
   (* Віднімаємо від балансу адреси-відправника кількість відправлених токенів *)
   senderAccount.balance := abs (senderAccount.balance - value);
   (* Оновлюємо запис про баланс відправника в storage *)
   s.ledger [from_] := senderAccount;
   (* Ще раз викликаємо функцію getAccount, щоб отримати або створити запис аккаунта для адреси-одержувача *)
   var destAccount: account:= getAccount (to_, s);
   (* Додаємо до балансу одержувача кількість відправлених токенів *)
   destAccount.balance:= destAccount.balance + value;
   (* Оновлюємо запис про баланс одержувача в storage *)
   s.ledger [to_]:= destAccount;
 }
 // повертаємо порожній список операцій і стан storage після виконання функції
with (noOperations, s)

function approve (const spender: address; const value: amt; var s: storage): return is
 block {
   (* Отримуємо дані облікового запису користувача *)
   var senderAccount: account:= getAccount (Tezos.sender, s);
   (* Отримуємо поточну кількість токенів, яку користувач дозволив відправити *)
   const spenderAllowance: amt = getAllowance (senderAccount, spender, s);
   if spenderAllowance> 0n and value> 0n then
     failwith ( "UnsafeAllowanceChange")
   else skip;
   (* Вносимо в дані облікового запису нову дозволену кількість токенів для витрачання *)
   senderAccount.allowances [spender]:= value;
   (* Оновлюємо сховище смарт-контракту *)
   s.ledger [Tezos.sender]:= senderAccount;
 } with (noOperations, s)

function getBalance (const owner: address; const contr: contract (amt); var s: storage): return is
 block {
     // присвоюємо константі ownerAccount дані облікового запису
   const ownerAccount: account = getAccount (owner, s);
 }
 // повертаємо проміжковому контракту баланс аккаунта
 with (list [transaction (ownerAccount.balance, 0tz, contr)], s)


function getAllowance (const owner: address; const spender: address; const contr: contract (amt); var s: storage): return is
 block {
     // отримуємо дані облікового запису, а з них — кількість дозволених для витрачання токенів
   const ownerAccount: account = getAccount (owner, s);
   const spenderAllowance: amt = getAllowance (ownerAccount, spender, s);
 } with (list [transaction (spenderAllowance, 0tz, contr)], s)


function getTotalSupply (const contr: contract (amt); var s: storage): return is
 block {
   skip
 } with (list [transaction (s.totalSupply, 0tz, contr)], s)

function main (const action: entryAction; var s: storage): return is
 block {
   skip
 } with case action of
   | Transfer (params) -> transfer (params.0, params.1.0, params.1.1, s)
   | Approve (params) -> approve (params.0, params.1, s)
   | GetBalance (params) -> getBalance (params.0, params.1, s)
   | GetAllowance (params) -> getAllowance (params.0.0, params.0.1, params.1, s)
   | GetTotalSupply (params) -> getTotalSupply (params.1, s)
 end;