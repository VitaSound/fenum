\ fenum-ulist.4th — universal односвязный список как struct (вариант A)
\
\ ulist — это заголовок (container с типом TYPE_ULIST), хранящий
\ указатель на цепочку внутренних узлов. Сами узлы скрыты от API.
\
\ Стек-конвенция:
\   - lst всегда top (последний аргумент перед словом).
\   - xt последний аргумент: `obj-a lst ulist-add`, `' xt lst ulist-each`.

require ./fenum-container.4th

\ ---------------------------------------------------------------
\ Заголовок ulist% расширяет container% на одно поле — head.
\ ---------------------------------------------------------------
container%
    cell% field ulist-head
constant ulist%

\ ---------------------------------------------------------------
\ Внутренние узлы (приватные, наружу не торчат)
\ ---------------------------------------------------------------
struct
    cell% field unode-addr
    cell% field unode-next
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

\ chain xt --     ; xt: ( addr -- )
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
\ Публичный API ulist
\ ---------------------------------------------------------------

\ -- lst        создать пустой ulist
: ulist-new ( -- lst )
    ulist% allocate throw
    TYPE_ULIST over obj-type !
    0 over ulist-head ! ;

\ lst -- flag
: ulist-empty? ( lst -- flag )
    ulist-head @ 0= ;

\ lst -- n
: ulist-len ( lst -- n )
    ulist-head @ unode-chain-len ;

\ addr lst --       добавить в голову (O(1))
: ulist-add ( addr lst -- )
    dup >r                  ( addr lst ; r: lst )
    ulist-head @            ( addr head )
    unode-new               ( node )
    r> ulist-head ! ;       \ записать новый head

\ addr lst -- flag
: ulist-contains? ( addr lst -- flag )
    ulist-head @ swap       ( head addr )
    unode-chain-find 0<> ;

\ n lst -- addr|0
: ulist-nth-addr ( n lst -- addr|0 )
    ulist-head @ swap       ( head n )
    unode-chain-nth
    dup if unode-addr @ then ;

\ xt lst --      ; xt: ( addr -- )
: ulist-each ( xt lst -- )
    ulist-head @ swap       ( head xt )
    unode-chain-each ;

\ lst --         in-place реверс цепочки
: ulist-reverse ( lst -- )
    dup ulist-head @ unode-chain-reverse
    swap ulist-head ! ;

\ lst --         удалить все узлы, lst остаётся пустым (валидным)
: ulist-clear ( lst -- )
    dup ulist-head @ unode-chain-free
    0 swap ulist-head ! ;

\ lst --         освободить узлы + сам заголовок (lst больше нельзя
\                использовать)
: ulist-dispose ( lst -- )
    dup ulist-head @ unode-chain-free
    free throw ;
