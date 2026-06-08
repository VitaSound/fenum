require ../forth-packages/ttester/1.2.1/ttester.4th
require ./fenum-test-common.4th

: %asc  ( a b -- flag )   swap @ swap @ <= ;
: %desc ( a b -- flag )   swap @ swap @ >= ;

\ ============== enum-each идентичен ulist-each =========
T{
  0 %sum !
  mk-tl
  v10 %tl @ ulist-add  v20 %tl @ ulist-add  v30 %tl @ ulist-add
  ' %add-to-sum %tl @ enum-each
  rm-tl
  %sum @
-> 60 }T

\ enum-each на пустом — не зовёт xt
T{
  0 %sum !
  mk-tl
  ' %add-to-sum %tl @ enum-each
  rm-tl
  %sum @
-> 0 }T

\ ============== enum-sort ascending ====================
\ Было head→tail: v30 v20 v10.  Sorted ascending: v10 v20 v30.
T{
  mk-tl
  v10 %tl @ ulist-add  v20 %tl @ ulist-add  v30 %tl @ ulist-add
  ' %asc %tl @ enum-sort %tl2 !
  0 %tl2 @ ulist-nth-addr
  1 %tl2 @ ulist-nth-addr
  2 %tl2 @ ulist-nth-addr
  rm-tl  rm-tl2
-> v10 v20 v30 }T

\ ============== enum-sort descending ===================
T{
  mk-tl
  v10 %tl @ ulist-add  v20 %tl @ ulist-add  v30 %tl @ ulist-add
  ' %desc %tl @ enum-sort %tl2 !
  0 %tl2 @ ulist-nth-addr
  1 %tl2 @ ulist-nth-addr
  2 %tl2 @ ulist-nth-addr
  rm-tl  rm-tl2
-> v30 v20 v10 }T

\ ============== enum-sort пустого ======================
T{
  mk-tl
  ' %asc %tl @ enum-sort %tl2 !
  %tl2 @ ulist-empty?
  %tl2 @ ulist-len
  rm-tl  rm-tl2
-> -1 0 }T

\ ============== enum-sort не меняет исходник ===========
T{
  mk-tl
  v10 %tl @ ulist-add  v20 %tl @ ulist-add  v30 %tl @ ulist-add
  ' %asc %tl @ enum-sort %tl2 !
  0 %tl  @ ulist-nth-addr          \ исходник: head=v30
  0 %tl2 @ ulist-nth-addr          \ sorted: head=v10
  %tl @ ulist-len
  rm-tl  rm-tl2
-> v30 v10 3 }T

\ ============== enum-sort на одном элементе ============
T{
  mk-tl
  v10 %tl @ ulist-add
  ' %asc %tl @ enum-sort %tl2 !
  %tl2 @ ulist-len
  0 %tl2 @ ulist-nth-addr
  rm-tl  rm-tl2
-> 1 v10 }T
