\ fenum-addrlist.4th — низкоуровневый список АДРЕСОВ (бывший ulist)
\
\ Элемент = голая ячейка-адрес, тип живёт снаружи (вариант 3:
\ адресный список остаётся примитивом). Узел: { addr, next }.
\ Потребители с адресной семантикой: flua (параметры), enum-sort.
\
\ ulist — это заголовок (container с типом TYPE_ADDR), хранящий
\ указатель на цепочку внутренних узлов. Сами узлы скрыты от API.
\
\ Стек-конвенция:
\   - lst всегда top (последний аргумент перед словом).
\   - xt последний аргумент: `obj-a lst addrlist-add`, `' xt lst addrlist-each`.

require ./fenum-container.4th

\ ---------------------------------------------------------------
\ Заголовок addrlist% расширяет container% на одно поле — head.
\ ---------------------------------------------------------------
container%
    cell% field addrlist-head
end-struct-const addrlist%

\ ---------------------------------------------------------------
\ Внутренние узлы (приватные, наружу не торчат)
\ ---------------------------------------------------------------
struct
    cell% field anode-addr
    cell% field anode-next
end-struct-const anode%

\ addr next -- node
: anode-new ( addr next -- node )
    anode% allocate throw >r
    swap r@ anode-addr !
    r@ anode-next !
    r> ;

\ chain -- n
: achain-len ( chain -- n )
    0 swap
    begin dup while
        swap 1+ swap anode-next @
    repeat drop ;

\ chain xt --     ; xt: ( addr -- )
: achain-each ( chain xt -- )
    >r begin dup while
        dup anode-addr @ r@ execute anode-next @
    repeat drop rdrop ;

\ chain addr -- node|0
: achain-find ( chain addr -- node|0 )
    >r begin
        dup while
            dup anode-addr @ r@ = if rdrop exit then
            anode-next @
        repeat
        rdrop ;

\ chain n -- node|0     0-based, вне диапазона → 0
: achain-nth ( chain n -- node|0 )
    dup 0< if 2drop 0 exit then
    0 ?do
        dup 0= if unloop exit then
        anode-next @
    loop ;

\ chain --     освобождает все узлы цепочки
: achain-free ( chain -- )
    begin dup while
        dup anode-next @ swap free throw
    repeat drop ;

\ chain -- chain'     in-place разворот связей; возвращает новую голову
: achain-reverse ( chain -- chain' )
    0 swap
    begin dup while
        dup anode-next @            ( acc cur rest )
        -rot                         ( rest acc cur )
        2dup anode-next !            \ cur.next = acc
        nip swap                     ( cur rest )
    repeat
    drop ;

\ ---------------------------------------------------------------
\ Публичный API ulist
\ ---------------------------------------------------------------

\ -- lst        создать пустой addrlist (obj-type = TYPE_ADDR,
\               чтобы enum-each/sort отличали его от термового ulist)
: addrlist-new ( -- lst )
    addrlist% allocate throw
    TYPE_ADDR over obj-type !
    0 over addrlist-head ! ;

\ lst -- flag
: addrlist-empty? ( lst -- flag )
    addrlist-head @ 0= ;

\ lst -- n
: addrlist-len ( lst -- n )
    addrlist-head @ achain-len ;

\ addr lst --       добавить в голову (O(1))
: addrlist-add ( addr lst -- )
    dup >r                  ( addr lst ; r: lst )
    addrlist-head @            ( addr head )
    anode-new               ( node )
    r> addrlist-head ! ;       \ записать новый head

\ addr lst -- flag
: addrlist-contains? ( addr lst -- flag )
    addrlist-head @ swap       ( head addr )
    achain-find 0<> ;

\ n lst -- addr|0
: addrlist-nth-addr ( n lst -- addr|0 )
    addrlist-head @ swap       ( head n )
    achain-nth
    dup if anode-addr @ then ;

\ xt lst --      ; xt: ( addr -- )
: addrlist-each ( xt lst -- )
    addrlist-head @ swap       ( head xt )
    achain-each ;

\ lst --         in-place реверс цепочки
: addrlist-reverse ( lst -- )
    dup addrlist-head @ achain-reverse
    swap addrlist-head ! ;

\ lst --         удалить все узлы, lst остаётся пустым (валидным)
: addrlist-clear ( lst -- )
    dup addrlist-head @ achain-free
    0 swap addrlist-head ! ;

\ lst --         освободить узлы + сам заголовок (lst больше нельзя
\                использовать)
: addrlist-dispose ( lst -- )
    dup addrlist-head @ achain-free
    free throw ;
