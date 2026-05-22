\ fenum-ulist.4th — universal односвязный список узлов (next + addr объекта)
\
\ Узел не хранит данные объекта, только адрес (ulist-addr) и ссылку (ulist-next).
\ Пустой список — 0 (ulist-null).
\
\ Узлы выделяются через allocate; освобождайте цепочку через ulist-free.

require struct.fs

struct
    cell% field ulist-next
    cell% field ulist-addr
constant ulist-node%

0 constant ulist-null

\ addr next -- node
: ulist-node ( addr next -- node )
    ulist-node% allocate throw >r
    swap r@ ulist-addr !
    r@ ulist-next !
    r> ;

\ addr list -- list
: ulist-cons ( addr list -- list )
    ulist-node ;

\ list -- flag
: ulist-empty? ( list -- flag )
    0= ;

\ node -- addr
: ulist-addr@ ( node -- addr )
    ulist-addr @ ;

\ node -- list
: ulist-next@ ( node -- list )
    ulist-next @ ;

\ node addr --
: ulist-addr! ( node addr -- )
    swap ulist-addr ! ;

\ node next --
: ulist-next! ( node next -- )
    swap ulist-next ! ;

\ list -- n
: ulist-len ( list -- n )
    0 swap
    begin dup while
        swap 1+ swap ulist-next@
    repeat drop ;

\ list xt --    ; xt ( addr -- )
: ulist-for-each ( list xt -- )
    >r begin dup while
        dup ulist-addr@ r@ execute ulist-next@
    repeat drop rdrop ;

\ list addr -- node|0
: ulist-find-addr ( list addr -- node|0 )
    >r begin
        dup while
            dup ulist-addr@ r@ = if rdrop exit then
            ulist-next@
        repeat
        rdrop ;

\ list addr -- flag
: ulist-contains? ( list addr -- flag )
    ulist-find-addr 0<> ;

\ list n -- node|0     ; 0-based, n<0 или n>=len → 0
: ulist-nth ( list n -- node|0 )
    dup 0< if 2drop 0 exit then
    0 ?do
        dup 0= if unloop exit then
        ulist-next@
    loop ;

\ list n -- addr|0
: ulist-nth-addr ( list n -- addr|0 )
    ulist-nth dup if ulist-addr@ then ;

\ list --     освобождает все узлы (объекты по addr НЕ трогает)
: ulist-free ( list -- )
    begin dup while
        dup ulist-next@ swap free throw
    repeat drop ;

\ list -- list'    новая цепочка, обратная к list (вход не модифицирует)
: ulist-reverse ( list -- list' )
    0 swap
    begin dup while
        dup ulist-addr@ rot ulist-cons swap
        ulist-next@
    repeat drop ;

\ list -- list'    поверхностная копия (новые узлы, те же addr)
: ulist-copy ( list -- list' )
    ulist-reverse
    dup ulist-reverse swap ulist-free ;

\ list1 list2 -- list   destructive: list2 подклеивается в хвост list1
\ list1 пуст → возвращает list2; list2 пуст → возвращает list1.
: ulist-append! ( list1 list2 -- list )
    over 0= if nip exit then
    dup  0= if drop exit then
    over                       ( l1 l2 cur )
    begin dup ulist-next@ ?dup while
        nip                    ( l1 l2 next )
    repeat                     ( l1 l2 last )
    swap ulist-next!           ( l1 )
    ;

\ list xt -- list'    ; xt ( addr -- addr' ), новые узлы со значениями xt(addr)
: ulist-map ( list xt -- list' )
    >r
    0 swap
    begin dup while
        dup ulist-addr@ r@ execute
        rot ulist-cons swap
        ulist-next@
    repeat drop
    rdrop
    dup ulist-reverse swap ulist-free ;
