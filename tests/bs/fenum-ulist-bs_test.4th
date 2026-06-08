require ../../forth-packages/ttester/1.2.1/ttester.4th
require ./fenum-bs-test-common.4th

T{ mk-tl  %tl @ ulist-empty?  rm-tl -> -1 }T
T{ mk-tl  %tl @ ulist-len     rm-tl ->  0 }T
T{ mk-tl  %tl @ obj-type @    rm-tl -> TYPE_ULIST }T

T{
  mk-tl
  v10 %tl @ ulist-add
  v20 %tl @ ulist-add
  v30 %tl @ ulist-add
  %tl @ ulist-len
  rm-tl
-> 3 }T

T{
  mk-tl
  v10 %tl @ ulist-add  v20 %tl @ ulist-add  v30 %tl @ ulist-add
  0 %tl @ ulist-nth-addr
  1 %tl @ ulist-nth-addr
  2 %tl @ ulist-nth-addr
  rm-tl
-> v30 v20 v10 }T

T{
  mk-tl
  v10 %tl @ ulist-add
  v20 %tl @ ulist-add
  v10 %tl @ ulist-contains?
  v20 %tl @ ulist-contains?
  v30 %tl @ ulist-contains?
  rm-tl
-> -1 -1 0 }T

T{
  0 %sum !
  mk-tl
  v10 %tl @ ulist-add  v20 %tl @ ulist-add  v30 %tl @ ulist-add
  ' %add-to-sum %tl @ ulist-each
  rm-tl
  %sum @
-> 60 }T

T{
  mk-tl
  v10 %tl @ ulist-add  v20 %tl @ ulist-add  v30 %tl @ ulist-add
  %tl @ ulist-reverse
  0 %tl @ ulist-nth-addr
  1 %tl @ ulist-nth-addr
  2 %tl @ ulist-nth-addr
  rm-tl
-> v10 v20 v30 }T

T{
  mk-tl
  v10 %tl @ ulist-add  v20 %tl @ ulist-add
  %tl @ ulist-clear
  %tl @ ulist-empty?
  %tl @ ulist-len
  rm-tl
-> -1 0 }T

T{
  mk-tl
  v10 %tl @ ulist-add
  -1 %tl @ ulist-nth-addr
   5 %tl @ ulist-nth-addr
  rm-tl
-> 0 0 }T

begin-structure demo%
    field: demo.val
end-structure

T{
  demo% allocate throw
  dup 42 swap demo.val !
  dup demo.val @
  swap free throw
-> 42 }T
