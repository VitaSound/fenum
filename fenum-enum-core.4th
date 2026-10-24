\ fenum-enum-core.4th — enum-each / enum-sort (без require backend)
\
\ Backend (struct.fs или begin-structure) должен быть загружен раньше:
\ container%, addrlist-*, TYPE_*, obj-type @.
\
\ ============ Контракт cmp для enum-sort (HOF) ====================
\
\   cmp-xt c enum-sort           \ cmp-xt — АДРЕС слова сравнения: ' cmp
\                                \ или 0 — дефолтное сравнение
\
\ cmp: ( el-a el-b -- flag ) — flag ≠ 0 означает «порядок не менять»,
\ el-a не позже el-b (отношение ≤). el-a / el-b — адрес элемента ТАК,
\ как его отдаёт enum-each для данного типа контейнера:
\
\   TYPE_ADDR    — адрес ячейки-элемента (модель addrlist);
\   TYPE_ULIST   — терм-адрес элемента (термовый список);
\   TYPE_HASHMAP — slot (ключ-терм на смещении 0 слота, значение-терм
\                  = slot + 3 cells): cmp сравнивает КЛЮЧИ, как в Elixir.
\
\ 0 вместо cmp-xt → дефолт: для TYPE_ADDR содержимое ячейки численно
\ (тип элемента живёт снаружи), для термовых — term-cmp.
\
\ Результат enum-sort: TYPE_ADDR → новый addrlist; TYPE_ULIST → новый
\ ulist (копии термов); TYPE_HASHMAP → ulist ПАР TM-PAIR (v1 = ключ-терм,
\ v2 = значение-терм — адреса В ПУЛЕ мапа: результат валиден, пока жив
\ исходный hashmap). Исходник не мутируется.

[IFDEF] enum-each [ELSE]

: %enum-unknown ( type -- )
    drop ." fenum-enum: unknown container type" cr abort ;

[IFDEF] hashmap-each [ELSE]
\ bs-путь: struct-backend (addrlist) не подключён — псевдонимы на
\ ulist-bs (та же адресная модель элемента), чтобы enum-each/sort
\ работали в обоих образах. Определяются ДО enum-each/sort.
: addrlist-new ( -- l )  ulist-new ;
: addrlist-add ( a l -- )  ulist-add ;
: addrlist-len ( l -- n )  ulist-len ;
: addrlist-each ( xt l -- )  ulist-each ;
[THEN]

[IFDEF] hashmap-each
\ struct-образ: addrlist (TYPE_ADDR), термовый ulist (TYPE_ULIST)
\ и hashmap — три разных контейнера
: enum-each ( xt c -- )
    dup obj-type @ case
        TYPE_ADDR of addrlist-each endof
        TYPE_ULIST of ulist-each endof
        TYPE_HASHMAP of hashmap-each endof
        %enum-unknown
    endcase ;
[ELSE]
\ struct-backend с hashmap не подключён (bs-путь): без TYPE_HASHMAP-ветки
: enum-each ( xt c -- )
    dup obj-type @ case
        TYPE_ULIST of addrlist-each endof
        %enum-unknown
    endcase ;
[THEN]

\ ---------------------------------------------------------------
\ Общая инфраструктура сортировки (массив адресов + bubble)
\ ---------------------------------------------------------------

variable %sort-array
variable %sort-n
variable %sort-idx
variable %sort-cmp-xt

\ дефолтный cmp для адресной модели: содержимое ячейки численно
: %cmp-addr-def ( a b -- flag )  swap @ swap @ <= ;

: %sort-collect ( addr -- )
    %sort-array @ %sort-idx @ cells + !
    1 %sort-idx +! ;

: %sort-at ( i -- value )
    cells %sort-array @ + @ ;

: %sort-at! ( value i -- )
    cells %sort-array @ + ! ;

: %sort-swap ( i j -- )
    over %sort-at over %sort-at
    3 roll
    %sort-at!
    swap %sort-at! ;

\ вызов HOF: cmp получает два адреса элементов из массива
: %sort-cmp ( i j -- flag )
    %sort-at swap %sort-at swap
    %sort-cmp-xt @ execute ;

: %sort-bubble ( n -- )
    dup 2 < if drop exit then
    dup 0 ?do
        dup 1- 0 ?do
            I I 1+ %sort-cmp 0= if
                I I 1+ %sort-swap
            then
        loop
    loop
    drop ;

\ n -- : выделить массив под n адресов
: %sort-begin ( n -- )
    cells allocate throw %sort-array !
    0 %sort-idx ! ;

\ c -- : собрать адреса элементов в массив (len уже в %sort-n)
: %sort-fill ( c -- )
    ['] %sort-collect swap enum-each ;

\ xt -- new : xt собирает результат из массива, затем освободить
\ (результат остаётся на стеке — free трогает только вершину-адрес)
: %sort-end ( build-xt -- new )
    execute %sort-array @ free throw ;

\ ---------------------------------------------------------------
\ TYPE_ADDR — адресный addrlist: элемент = адрес ячейки
\ ---------------------------------------------------------------

: %sort-to-addrlist ( -- new-addrlist )
    addrlist-new
    %sort-n @ 0 ?do
        %sort-n @ 1- I -  %sort-at
        over addrlist-add
    loop ;

: %sort-addr ( cmp-xt c -- new-addrlist )
    { cmp c }
    cmp 0= if ['] %cmp-addr-def else cmp then %sort-cmp-xt !
    c addrlist-len dup %sort-n !
    dup 0= if drop addrlist-new exit then
    %sort-begin
    c %sort-fill
    %sort-n @ %sort-bubble
    ['] %sort-to-addrlist %sort-end ;

\ ---------------------------------------------------------------
\ TYPE_ULIST — термовый ulist: элемент = терм-адрес,
\ результат — новый ulist с копиями термов
\ ---------------------------------------------------------------

variable %sort-out                      \ собираемый контейнер (без r@ в ?do:
                                        \ loop держит return stack)

[IFDEF] term-cmp
: %sort-to-ulist ( -- new-ulist )
    ulist-new %sort-out !
    %sort-n @ 0 ?do
        %sort-n @ 1- I -  %sort-at      ( term-addr )
        term@                           ( vt v1 v2 )
        %sort-out @ ulist-add
    loop
    %sort-out @ ;

: %sort-ulist ( cmp-xt c -- new-ulist )
    { cmp c }
    cmp 0= if ['] term-cmp else cmp then %sort-cmp-xt !
    c ulist-len dup %sort-n !
    dup 0= if drop ulist-new exit then
    %sort-begin
    c %sort-fill
    %sort-n @ %sort-bubble
    ['] %sort-to-ulist %sort-end ;
[THEN]

\ ---------------------------------------------------------------
\ TYPE_HASHMAP — сортировка ПО КЛЮЧАМ (Elixir-семантика):
\ cmp сравнивает slot'ы (на смещении 0 — ключ-терм, поэтому
\ дефолтный term-cmp работает напрямую), результат — ulist ПАР
\ TM-PAIR, ключи по возрастанию, значения — в порядке ключей.
\ ---------------------------------------------------------------

[IFDEF] term-cmp
: %add-pair ( slot lst -- )
    { s l }
    TM-PAIR s s 3 cells + l ulist-add ;    \ ключ-терм = slot, значение = +3 cells

: %sort-to-pairs ( -- new-ulist )
    ulist-new %sort-out !
    %sort-n @ 0 ?do
        %sort-n @ 1- I -  %sort-at         ( slot )
        %sort-out @ %add-pair
    loop
    %sort-out @ ;

: %sort-hmap ( cmp-xt c -- new-ulist )
    { cmp c }
    cmp 0= if ['] term-cmp else cmp then %sort-cmp-xt !
    c hashmap-len dup %sort-n !
    dup 0= if drop ulist-new exit then
    %sort-begin
    c %sort-fill
    %sort-n @ %sort-bubble
    ['] %sort-to-pairs %sort-end ;
[THEN]

\ ---------------------------------------------------------------
\ Диспетчер
\ ---------------------------------------------------------------

[IFDEF] hashmap-each
: enum-sort ( cmp-xt c -- new )
    dup obj-type @ case
        TYPE_ADDR of %sort-addr endof
        TYPE_ULIST of %sort-ulist endof
        TYPE_HASHMAP of %sort-hmap endof
        %enum-unknown
    endcase ;
[ELSE]
\ bs: TYPE_ULIST — адресная модель (ulist-bs)
: enum-sort ( cmp-xt c -- new )
    dup obj-type @ case
        TYPE_ULIST of %sort-addr endof
        %enum-unknown
    endcase ;
[THEN]

[THEN]
