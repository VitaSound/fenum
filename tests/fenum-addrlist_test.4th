\ tests/fenum-addrlist_test.4th — низкоуровневый список АДРЕСОВ
\ (бывший ulist): элемент = голая ячейка-адрес, тип снаружи.
require ../forth-packages/ttester/1.2.1/ttester.4th
require ./fenum-test-common.4th

\ ============== базовое ===============================
T{ mk-tl  %tl @ addrlist-empty?  rm-tl -> -1 }T
T{ mk-tl  %tl @ addrlist-len     rm-tl ->  0 }T
T{ mk-tl  %tl @ obj-type @    rm-tl -> TYPE_ADDR }T

\ ============== addrlist-add + len ========================
T{
  mk-tl
  v10 %tl @ addrlist-add
  v20 %tl @ addrlist-add
  v30 %tl @ addrlist-add
  %tl @ addrlist-len
  rm-tl
-> 3 }T

\ ============== addrlist-add кладёт в голову ==============
\ После v10,v20,v30 порядок head→tail = v30 v20 v10.
T{
  mk-tl
  v10 %tl @ addrlist-add  v20 %tl @ addrlist-add  v30 %tl @ addrlist-add
  0 %tl @ addrlist-nth-addr
  1 %tl @ addrlist-nth-addr
  2 %tl @ addrlist-nth-addr
  rm-tl
-> v30 v20 v10 }T

\ ============== addrlist-contains? ========================
T{
  mk-tl
  v10 %tl @ addrlist-add
  v20 %tl @ addrlist-add
  v10 %tl @ addrlist-contains?
  v20 %tl @ addrlist-contains?
  v30 %tl @ addrlist-contains?
  rm-tl
-> -1 -1 0 }T

\ ============== addrlist-each: сумма ======================
T{
  0 %sum !
  mk-tl
  v10 %tl @ addrlist-add  v20 %tl @ addrlist-add  v30 %tl @ addrlist-add
  ' %add-to-sum %tl @ addrlist-each
  rm-tl
  %sum @
-> 60 }T

\ ============== addrlist-reverse ==========================
\ Было: v30 v20 v10.  После reverse: v10 v20 v30.
T{
  mk-tl
  v10 %tl @ addrlist-add  v20 %tl @ addrlist-add  v30 %tl @ addrlist-add
  %tl @ addrlist-reverse
  0 %tl @ addrlist-nth-addr
  1 %tl @ addrlist-nth-addr
  2 %tl @ addrlist-nth-addr
  rm-tl
-> v10 v20 v30 }T

\ reverse пустого
T{
  mk-tl
  %tl @ addrlist-reverse
  %tl @ addrlist-empty?
  rm-tl
-> -1 }T

\ reverse одного
T{
  mk-tl
  v10 %tl @ addrlist-add
  %tl @ addrlist-reverse
  0 %tl @ addrlist-nth-addr
  %tl @ addrlist-len
  rm-tl
-> v10 1 }T

\ ============== addrlist-clear ============================
T{
  mk-tl
  v10 %tl @ addrlist-add  v20 %tl @ addrlist-add
  %tl @ addrlist-clear
  %tl @ addrlist-empty?
  %tl @ addrlist-len
  rm-tl
-> -1 0 }T

\ clear → можно добавлять заново
T{
  mk-tl
  v10 %tl @ addrlist-add
  %tl @ addrlist-clear
  v20 %tl @ addrlist-add  v30 %tl @ addrlist-add
  %tl @ addrlist-len
  rm-tl
-> 2 }T

\ ============== addrlist-nth-addr вне диапазона ===========
T{
  mk-tl
  v10 %tl @ addrlist-add
  -1 %tl @ addrlist-nth-addr
   5 %tl @ addrlist-nth-addr
  rm-tl
-> 0 0 }T
