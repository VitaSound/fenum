\ fenum-ulist.4th — universal односвязный список как класс container
\
\ ulist реализует интерфейс container: add/each/len/contains?/nth-addr/
\ clear/reverse/dispose. Узлы — низкоуровневая struct unode%, наружу
\ не торчат.

require ./fenum-container.4th

\ ---------------------------------------------------------------
\ Внутренние узлы (обычная gforth struct, не объекты mini-oof2)
\ ---------------------------------------------------------------
struct
    cell% field unode-next
    cell% field unode-addr
constant unode%

\ addr next -- node
: unode-new ( addr next -- node )
    unode% allocate throw >r
    swap r@ unode-addr !
    r@ unode-next !
    r> ;

\ chain -- n
: unode-chain-len ( chain -- n )
    0 swap
    begin dup while
        swap 1+ swap unode-next @
    repeat drop ;

\ chain xt --   ; xt ( addr -- )
: unode-chain-each ( chain xt -- )
    >r begin dup while
        dup unode-addr @ r@ execute unode-next @
    repeat drop rdrop ;

\ chain addr -- node|0
: unode-chain-find ( chain addr -- node|0 )
    >r begin
        dup while
            dup unode-addr @ r@ = if rdrop exit then
            unode-next @
        repeat
        rdrop ;

\ chain n -- node|0     0-based, вне диапазона → 0
: unode-chain-nth ( chain n -- node|0 )
    dup 0< if 2drop 0 exit then
    0 ?do
        dup 0= if unloop exit then
        unode-next @
    loop ;

\ chain --     освобождает все узлы цепочки
: unode-chain-free ( chain -- )
    begin dup while
        dup unode-next @ swap free throw
    repeat drop ;

\ chain -- chain'     in-place разворот связей; возвращает новую голову
: unode-chain-reverse ( chain -- chain' )
    0 swap
    begin dup while
        dup unode-next @            ( acc cur rest )
        -rot                         ( rest acc cur )
        2dup unode-next !            \ cur.next = acc
        nip swap                     ( cur rest )
    repeat
    drop ;

\ ---------------------------------------------------------------
\ Класс ulist : container
\ ---------------------------------------------------------------
container class
    field: ulist-head
end-class ulist
standard:field

ulist :method empty? ( -- flag )
    ulist-head @ 0= ;

ulist :method len ( -- n )
    ulist-head @ unode-chain-len ;

ulist :method add ( addr -- )
    ulist-head @ unode-new ulist-head ! ;

ulist :method contains? ( addr -- flag )
    ulist-head @ swap unode-chain-find 0<> ;

ulist :method nth-addr ( n -- addr|0 )
    ulist-head @ swap unode-chain-nth
    dup if unode-addr @ then ;

ulist :method each ( xt -- )
    ulist-head @ swap unode-chain-each ;

ulist :method clear ( -- )
    ulist-head @ unode-chain-free
    0 ulist-head ! ;

ulist :method reverse ( -- )
    ulist-head @ unode-chain-reverse ulist-head ! ;

ulist :method dispose ( -- )
    ulist-head @ unode-chain-free
    dispose-self ;
