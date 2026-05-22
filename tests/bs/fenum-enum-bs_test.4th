require ../../forth-packages/ttester/1.1.0/ttester.4th
require ./fenum-bs-test-common.4th

: %asc  ( a b -- flag )   swap @ swap @ <= ;

T{
  0 %sum !
  mk-tl
  v10 %tl @ ulist-add  v20 %tl @ ulist-add  v30 %tl @ ulist-add
  ' %add-to-sum %tl @ enum-each
  rm-tl
  %sum @
-> 60 }T

T{
  mk-tl
  v10 %tl @ ulist-add  v20 %tl @ ulist-add  v30 %tl @ ulist-add
  ' %asc %tl @ enum-sort %tl2 !
  0 %tl2 @ ulist-nth-addr
  1 %tl2 @ ulist-nth-addr
  2 %tl2 @ ulist-nth-addr
  rm-tl  rm-tl2
-> v10 v20 v30 }T

T{
  mk-tl
  v10 %tl @ ulist-add
  ' %asc %tl @ enum-sort %tl2 !
  %tl2 @ ulist-len
  0 %tl2 @ ulist-nth-addr
  rm-tl  rm-tl2
-> 1 v10 }T
