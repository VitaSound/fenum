require ../forth-packages/ttester/1.2.1/ttester.4th
require ./fenum-test-common.4th

\ ============== базовое ===============================
T{ mk-tl  %tl @ ulist-empty?  rm-tl -> -1 }T
T{ mk-tl  %tl @ ulist-len     rm-tl ->  0 }T
T{ mk-tl  %tl @ obj-type @    rm-tl -> TYPE_ULIST }T

\ ============== ulist-add + len ========================
T{
  mk-tl
  v10 %tl @ ulist-add
  v20 %tl @ ulist-add
  v30 %tl @ ulist-add
  %tl @ ulist-len
  rm-tl
-> 3 }T

\ ============== ulist-add кладёт в голову ==============
\ После v10,v20,v30 порядок head→tail = v30 v20 v10.
T{
  mk-tl
  v10 %tl @ ulist-add  v20 %tl @ ulist-add  v30 %tl @ ulist-add
  0 %tl @ ulist-nth-addr
  1 %tl @ ulist-nth-addr
  2 %tl @ ulist-nth-addr
  rm-tl
-> v30 v20 v10 }T

\ ============== ulist-contains? ========================
T{
  mk-tl
  v10 %tl @ ulist-add
  v20 %tl @ ulist-add
  v10 %tl @ ulist-contains?
  v20 %tl @ ulist-contains?
  v30 %tl @ ulist-contains?
  rm-tl
-> -1 -1 0 }T

\ ============== ulist-each: сумма ======================
T{
  0 %sum !
  mk-tl
  v10 %tl @ ulist-add  v20 %tl @ ulist-add  v30 %tl @ ulist-add
  ' %add-to-sum %tl @ ulist-each
  rm-tl
  %sum @
-> 60 }T

\ ============== ulist-reverse ==========================
\ Было: v30 v20 v10.  После reverse: v10 v20 v30.
T{
  mk-tl
  v10 %tl @ ulist-add  v20 %tl @ ulist-add  v30 %tl @ ulist-add
  %tl @ ulist-reverse
  0 %tl @ ulist-nth-addr
  1 %tl @ ulist-nth-addr
  2 %tl @ ulist-nth-addr
  rm-tl
-> v10 v20 v30 }T

\ reverse пустого
T{
  mk-tl
  %tl @ ulist-reverse
  %tl @ ulist-empty?
  rm-tl
-> -1 }T

\ reverse одного
T{
  mk-tl
  v10 %tl @ ulist-add
  %tl @ ulist-reverse
  0 %tl @ ulist-nth-addr
  %tl @ ulist-len
  rm-tl
-> v10 1 }T

\ ============== ulist-clear ============================
T{
  mk-tl
  v10 %tl @ ulist-add  v20 %tl @ ulist-add
  %tl @ ulist-clear
  %tl @ ulist-empty?
  %tl @ ulist-len
  rm-tl
-> -1 0 }T

\ clear → можно добавлять заново
T{
  mk-tl
  v10 %tl @ ulist-add
  %tl @ ulist-clear
  v20 %tl @ ulist-add  v30 %tl @ ulist-add
  %tl @ ulist-len
  rm-tl
-> 2 }T

\ ============== ulist-nth-addr вне диапазона ===========
T{
  mk-tl
  v10 %tl @ ulist-add
  -1 %tl @ ulist-nth-addr
   5 %tl @ ulist-nth-addr
  rm-tl
-> 0 0 }T
