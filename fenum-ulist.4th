\ fenum-ulist.4th — универсальный список ТЕРМОВ (вариант 3, Elixir-стиль)
\
\ Элемент хранится САМ ПО СЕБЕ — терм из общего слоя fenum-term:
\   узел: [ type  v1  v2  next ]   (4 ячейки; терм — на смещении 0,
\                                    поэтому работают ОБЩИЕ t-type/t-v1/t-v2;
\                                    next — 3 cells)
\ Адресная модель прежнего ulist вынесена в fenum-addrlist.4th.
\
\ Стек-конвенция fenum: контейнер всегда top.
\ Ключ/элемент TM-STR хранится без копии (ptr,len).

require ./fenum-container.4th
require ./fenum-term.4th

[IFDEF] ulist% [ELSE]
container%
    cell% field ulist-head
end-struct-const ulist%
[THEN]

\ ---------------------------------------------------------------
\ Узловый слой (приватный)
\ ---------------------------------------------------------------

[IFDEF] nd-next [ELSE]
: nd-next ( nd -- nd' ) 3 cells + ;       \ адрес ячейки next
4 cells constant nd-size

\ новый узел: терм (vt v1 v2) + next
: nd-new ( vt v1 v2 next -- nd )
    { vt v1 v2 nx }                      \ вход ушёл в локалы, стек чист
    nd-size allocate throw >r
    vt v1 v2 r@ term!                    \ ровно 4 значения: ( type v1 v2 t=nd )
    nx r@ nd-next !
    r> ;

\ chain nd -- chain'     in-place разворот связей
: nd-chain-reverse ( chain -- chain' )
    0 swap
    begin dup while
        dup nd-next @             ( acc cur rest )
        -rot                      ( rest acc cur )
        2dup nd-next !            \ cur.next = acc
        nip swap                  ( cur rest )
    repeat
    drop ;

\ chain -- n
: nd-chain-len ( chain -- n )
    0 swap
    begin dup while
        swap 1+ swap nd-next @
    repeat drop ;

\ chain xt --      ; xt: ( term-addr -- )
: nd-chain-each ( chain xt -- )
    >r begin dup while
        dup r@ execute nd-next @
    repeat drop rdrop ;

\ chain n -- nd|0     0-based, вне диапазона → 0
: nd-chain-nth ( chain n -- nd|0 )
    dup 0< if 2drop 0 exit then
    0 ?do
        dup 0= if unloop exit then
        nd-next @
    loop ;

\ chain --         освобождает все узлы цепочки
: nd-chain-free ( chain -- )
    begin dup while
        dup nd-next @ swap free throw
    repeat drop ;
[THEN]

\ ---------------------------------------------------------------
\ Публичный API
\ ---------------------------------------------------------------

\ -- lst        создать пустой терм-список
: ulist-new ( -- lst )
    ulist% allocate throw
    TYPE_ULIST over obj-type !
    0 over ulist-head ! ;

\ lst -- flag
: ulist-empty? ( lst -- flag )
    ulist-head @ 0= ;

\ lst -- n
: ulist-len ( lst -- n )
    ulist-head @ nd-chain-len ;

\ vt v1 v2 lst --      добавить терм в голову (O(1), prepend как [h|t])
: ulist-add ( vt v1 v2 lst -- )
    dup >r                     ( vt v1 v2 lst ; r: lst )
    ulist-head @               ( vt v1 v2 head )
    nd-new                     ( nd )
    r> ulist-head ! ;

\ vt v1 v2 lst -- flag       содержится ли терм (term=, для строк compare)
: ulist-contains-term? ( vt v1 v2 lst -- flag )
    { vt v1 v2 lst }
    lst ulist-head @
    begin dup while
        dup t-type @ vt = if
            dup vt v1 v2 term-s= if drop true exit then
        then
        nd-next @
    repeat
    drop false ;

\ n lst -- vt v1 v2        n-й терм, 0-based; вне диапазона → 0 0 0
: ulist-nth-term ( n lst -- vt v1 v2 )
    ulist-head @ swap       ( head n )
    nd-chain-nth
    dup if term@ else drop 0 0 0 then ;   \ 0 от chain — снять, вернуть ровно тройку

\ xt lst --      ; xt: ( term-addr -- )
: ulist-each ( xt lst -- )
    ulist-head @ swap       ( head xt )
    nd-chain-each ;

\ lst --         in-place реверс
: ulist-reverse ( lst -- )
    dup ulist-head @ nd-chain-reverse
    swap ulist-head ! ;

\ lst --         удалить все узлы; lst остаётся валидным пустым
: ulist-clear ( lst -- )
    dup ulist-head @ nd-chain-free
    0 swap ulist-head ! ;

\ lst --         освободить узлы + сам заголовок (lst больше нельзя)
: ulist-dispose ( lst -- )
    dup ulist-head @ nd-chain-free
    free throw ;
