\ fenum-enum.4th — Elixir-style общие операции над container'ами
\
\ Слова enum-* — это диспетчеры по obj-type. Каждое знает реализации
\ для известных типов и направляет вызов соответствующему ulist-*,
\ hashmap-* и т.д.
\
\ Стек-конвенция: контейнер всегда top.
\   xt c enum-each
\   xt c enum-sort

require ./fenum-container.4th
require ./fenum-ulist.4th

\ ---------------------------------------------------------------
\ Диспетчер: проверка типа c, фейл если неизвестный
\ ---------------------------------------------------------------
: %enum-unknown ( type -- )
    drop ." fenum-enum: unknown container type" cr abort ;

\ ===============================================================
\ enum-each ( xt c -- )      ; xt: ( addr -- )
\ ===============================================================
: enum-each ( xt c -- )
    dup obj-type @ case
        TYPE_ULIST of ulist-each endof
        %enum-unknown
    endcase ;

\ ---------------------------------------------------------------
\ Сортировка через массив (для любого типа сводится к ulist через
\ enum-each: собираем addr'ы в массив, сортируем bubble, кладём
\ обратно в новый ulist в правильном порядке).
\ ---------------------------------------------------------------

variable %sort-array
variable %sort-n
variable %sort-idx
variable %sort-cmp-xt

\ собрать addr в массив (используется как xt в enum-each)
: %sort-collect ( addr -- )
    %sort-array @ %sort-idx @ cells + !
    1 %sort-idx +! ;

\ i -- value         значение по индексу
: %sort-at ( i -- value )
    cells %sort-array @ + @ ;

\ value i --        записать по индексу
: %sort-at! ( value i -- )
    cells %sort-array @ + ! ;

\ i j --            обменять a[i] и a[j]
: %sort-swap ( i j -- )
    over %sort-at over %sort-at      ( i j a[i] a[j] )
    3 roll                            ( j a[i] a[j] i )
    %sort-at!                         ( j a[i] )
    swap %sort-at! ;

\ i j -- flag       cmp(a[i], a[j]); true означает «a[i] должен идти перед a[j]»
: %sort-cmp ( i j -- flag )
    %sort-at swap %sort-at swap       ( a[i] a[j] )
    %sort-cmp-xt @ execute ;

\ n --              bubble sort массива длины n
: %sort-bubble ( n -- )
    dup 2 < if drop exit then
    dup 0 ?do                        \ i = 0..n-1
        dup 1- 0 ?do                 \ j = 0..n-2
            I I 1+ %sort-cmp 0= if
                I I 1+ %sort-swap
            then
        loop
    loop
    drop ;

\ ===============================================================
\ enum-sort ( xt c -- new-ulist )
\
\ xt: ( a b -- flag ); flag=true означает «a должен идти перед b».
\ Всегда возвращает новый ulist (как Enum.sort в Elixir всегда
\ возвращает List).
\ ===============================================================

: %sort-to-ulist ( -- new-ulist )
    ulist-new                         ( result )
    %sort-n @ 0 ?do
        %sort-array @
        %sort-n @ 1- I -  cells +     \ array + (n-1-i)*cell
        @                              \ array[n-1-i]
        over ulist-add
    loop ;

: enum-sort ( xt c -- new-ulist )
    \ stack: xt c
    dup obj-type @ case
        TYPE_ULIST of endof
        %enum-unknown
    endcase
    \ После проверки type на стеке: xt c
    swap %sort-cmp-xt !               ( c )
    dup ulist-len dup %sort-n !       \ для ulist
    0= if drop ulist-new exit then
    %sort-n @ cells allocate throw %sort-array !
    0 %sort-idx !
    ['] %sort-collect swap enum-each
    %sort-n @ %sort-bubble
    %sort-to-ulist
    %sort-array @ free throw ;
