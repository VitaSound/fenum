\ fenum-hashmap.4th — хеш-мапа (struct.fs backend)
\
\ Ключ и значение — термы в стиле Erlang/Elixir: любые типы, отдельное
\ поле-тег (TM-*) как внутренняя деталь (rtty, клиенту API это не видно).
\ Значением может быть и другая мапа (TM-MAP, v1 = адрес) — вложенность
\ бесплатна, как map-в-map в Elixir.
\
\ Устройство:
\   заголовок (container%): obj-type, count, cap, pool;
\   пул: cap слотов по 6 ячеек: ключ-терм (kt k1 k2) + значение (vt v1 v2);
\   открытая адресация, линейное пробирование, хеш по байтам ключа;
\   цепочка прерывается на TM-NONE (пусто);
\   hashmap-del пересобирает пул (без tombstone — просто и корректно);
\   переполнение (cap пробов без места) — throw.
\
\ Стек-конвенция fenum: контейнер всегда top.
\ Ключ TM-STR хранится без копии (указатель живёт у владельца,
\ как в ulist-add).

require ./fenum-container.4th
require ./fenum-ulist.4th
require ./fenum-term.4th

\ ---------------------------------------------------------------
\ Типы термов (общие для ключей и значений)
\ ---------------------------------------------------------------

\ ---------------------------------------------------------------
\ Структуры
\ ---------------------------------------------------------------

[IFDEF] hashmap% [ELSE]
128 constant hashmap-capacity           \ фиксированная ёмкость (v1, без роста)

container%
    cell% field hmap-count
    cell% field hmap-cap
    cell% field hmap-pool
end-struct-const hashmap%

\ слот пула: ключ-терм + значение-терм = 6 ячеек
struct
    cell% field hmap-kt
    cell% field hmap-k1
    cell% field hmap-k2
    cell% field hmap-vt
    cell% field hmap-v1
    cell% field hmap-v2
end-struct-const hmap-slot%

\ слот №i в пуле с базой base
: hmap-slot ( base i -- slot ) hmap-slot% * + ;

\ хеш терма-ключа (mod берёт вызывающий)
: hmap-hash ( kt k1 k2 -- h )
    { kt k1 k2 }
    kt TM-STR = if
        0 k1 k2 bounds ?do i c@ swap 31 * + loop
    else
        k1 k2 +
    then ;

\ слот ключа в цепочке хеша: slot|0 — ключа нет
variable hm-idx                              \ рабочий индекс проба (однопоточный код)

: hmap-probe-key ( pool cap kt k1 k2 -- slot|0 )
    { pool cap kt k1 k2 }
    kt k1 k2 hmap-hash cap /mod drop hm-idx !
    cap 0 ?do
        pool hm-idx @ hmap-slot
        dup hmap-kt @ 0= if drop 0 unloop exit then
        dup kt k1 k2 term-s= if unloop exit then
        drop
        hm-idx @ 1+ cap mod hm-idx !
    loop
    0 ;

\ первый свободный слот цепочки: slot|0 — места нет
: hmap-probe-free ( pool cap kt k1 k2 -- slot|0 )
    { pool cap kt k1 k2 }
    kt k1 k2 hmap-hash cap /mod drop hm-idx !
    cap 0 ?do
        pool hm-idx @ hmap-slot
        dup hmap-kt @ 0= if unloop exit then
        drop
        hm-idx @ 1+ cap mod hm-idx !
    loop
    0 ;

\ вставка без проверки существования ключа (вызывающий уверен в месте)
variable hm-sl                               \ рабочий слот

: hmap-put-raw ( pool cap kt k1 k2 vt v1 v2 -- )
    { pool cap kt k1 k2 vt v1 v2 }
    pool cap kt k1 k2 hmap-probe-free hm-sl !
    hm-sl @ 0= if -1 throw then              \ переполнение: места нет
    v2 hm-sl @ hmap-v2 !  v1 hm-sl @ hmap-v1 !  vt hm-sl @ hmap-vt !
    k2 hm-sl @ hmap-k2 !  k1 hm-sl @ hmap-k1 !  kt hm-sl @ hmap-kt ! ;

[THEN]

\ ---------------------------------------------------------------
\ Публичный API
\ ---------------------------------------------------------------

\ -- m          создать пустую мапу
: hashmap-new ( -- m )
    hashmap% allocate throw { m }
    TYPE_HASHMAP m obj-type !
    0 m hmap-count !
    hashmap-capacity m hmap-cap !
    hashmap-capacity hmap-slot% * allocate throw m hmap-pool !
    m hmap-pool @ hashmap-capacity hmap-slot% * 0 fill
    m ;

\ kt k1 k2 vt v1 v2 m --      записать (новый ключ или перезаписать)
: hashmap-set ( kt k1 k2 vt v1 v2 m -- )
    { kt k1 k2 vt v1 v2 m }
    m hmap-pool @ m hmap-cap @ kt k1 k2 hmap-probe-key hm-sl !
    hm-sl @ if
        v2 hm-sl @ hmap-v2 !  v1 hm-sl @ hmap-v1 !  vt hm-sl @ hmap-vt !
        exit
    then
    m hmap-pool @ m hmap-cap @ kt k1 k2 vt v1 v2 hmap-put-raw
    1 m hmap-count +! ;

\ kt k1 k2 m -- vt v1 v2 flag    флаг = ВЕРХНИЙ; если ключа нет — 0 0 0 false
: hashmap-get ( kt k1 k2 m -- vt v1 v2 flag )
    { kt k1 k2 m }
    m hmap-pool @ m hmap-cap @ kt k1 k2 hmap-probe-key hm-sl !
    hm-sl @ if
        hm-sl @ hmap-vt @  hm-sl @ hmap-v1 @  hm-sl @ hmap-v2 @  true
    else
        0 0 0 false
    then ;

\ kt k1 k2 m -- flag
: hashmap-has? ( kt k1 k2 m -- flag )
    { kt k1 k2 m }
    m hmap-pool @ m hmap-cap @ kt k1 k2 hmap-probe-key 0<> ;

\ kt k1 k2 m -- flag          удалить ключ (true) или ключа не было (false)
\ Пересборка: новый пул + перенос всех, кроме удаляемого ключа.
variable hm-pool  variable hm-cap  variable hm-np  variable hm-src  variable hm-dst

: hashmap-del ( kt k1 k2 m -- flag )
    { kt k1 k2 m }
    m hmap-pool @ hm-pool !
    m hmap-cap @ hm-cap !
    hm-pool @ hm-cap @ kt k1 k2 hmap-probe-key hm-sl !
    hm-sl @ 0= if false exit then
    \ новый пул: перенос занятых слотов, кроме удаляемого ключа
    hm-cap @ hmap-slot% * allocate throw hm-np !
    hm-np @ hm-cap @ hmap-slot% * 0 fill
    hm-cap @ 0 ?do
        hm-pool @ i hmap-slot hm-src !
        hm-src @ hmap-kt @ 0<> if
            hm-src @ kt k1 k2 term-s= 0= if
                hm-np @ hm-cap @ hm-src @ hmap-kt @
                hm-src @ hmap-k1 @ hm-src @ hmap-k2 @
                hmap-probe-free hm-dst !
                hm-dst @ 0= if -1 throw then
                hm-src @ hm-dst @ hmap-slot% cmove
            then
        then
    loop
    hm-pool @ free throw
    hm-np @ m hmap-pool !
    m hmap-count @ 1- m hmap-count !
    true ;

\ xt m --          ; xt: ( slot -- ) для каждого занятого слота
: hashmap-each ( xt m -- )
    { xt m }
    m hmap-cap @ 0 ?do
        m hmap-pool @ i hmap-slot
        dup hmap-kt @ if
            xt execute
        else
            drop                            \ пустой слот: снять адрес
        then
    loop ;

\ m -- n
: hashmap-len ( m -- n ) hmap-count @ ;

\ m -- flag
: hashmap-empty? ( m -- flag ) hmap-count @ 0= ;

\ m --            обнулить (m остаётся валидной пустой)
: hashmap-clear ( m -- )
    { m }
    m hmap-pool @ m hmap-cap @ hmap-slot% * 0 fill
    0 m hmap-count ! ;

\ m --             освободить пул + заголовок (m больше нельзя использовать)
: hashmap-dispose ( m -- )
    dup hmap-pool @ free throw
    free throw ;
