\ fenum-term.4th — общий терм-слой fenum (уровень 0)
\
\ Терм — единица данных «любого типа» в духе Erlang/Elixir: три ячейки
\   [ type  v1  v2 ]
\ с полем-тегом типа (TM-*): клиент видит только слова API, тег —
\ внутренняя деталь (rtty). По этому формату хранятся и элементы
\ терм-списка, и ключ/значение в слоте hashmap — т.е. оба контейнера
\ оперируют ОДНИМИ и теми же словами.
\
\   TM-INT  v1 = целое
\   TM-STR  v1 = ptr, v2 = len   (хранение без копии — как в ulist-add)
\   TM-MAP  v1 = адрес другой hashmap   (вложенность бесплатна)
\   TM-LST  v1 = адрес ulist
\   TM-PTR  v1 = голый адрес (адрес структуры и т.п.)
\
\ Слова-поля в стиле struct.fs: ( term-адрес -- сдвинутый-адрес ), т.е.
\   addr t-v1 @  — прочитать ячейку v1 терма на addr.

[IFDEF] TM-NONE [ELSE]
0 constant TM-NONE                     \ пусто / удалено (признак занятости слота)
1 constant TM-INT
2 constant TM-STR
3 constant TM-MAP
4 constant TM-LST
5 constant TM-PTR
6 constant TM-PAIR                \ пара термов: v1 = адрес терма-ключа,
                                  \ v2 = адрес терма-значения
                                  \ (адреса живут в пуле hashmap, пока жив мап)
[THEN]

\ ---- поля терма (offset 0 / 1 cell / 2 cells) ----

[IFDEF] t-v1 [ELSE]
: t-type ( t -- t ) ;                 \ смещение 0: адрес сам себе (identity)
: t-v1   ( t -- t' ) 1 cells + ;
: t-v2   ( t -- t' ) 2 cells + ;
[THEN]

\ ---- запись / чтение ----

: term! ( type v1 v2 t -- )
    { type v1 v2 t }
    type t t-type !  v1 t t-v1 !  v2 t t-v2 ! ;

: term@ ( t -- type v1 v2 )
    dup t-type @ over t-v1 @ rot t-v2 @ ;

\ ---- равенство ----

\ два терма по адресам; для TM-STR — содержимое строк (compare)
: term= ( a b -- flag )
    { at bt }
    at t-type @ bt t-type @ <> if false exit then
    at t-type @ TM-STR = if
        at t-v1 @ at t-v2 @ bt t-v1 @ bt t-v2 @ compare 0=
    else
        at t-v1 @ bt t-v1 @ = at t-v2 @ bt t-v2 @ = and
    then ;

\ терм со стека против терма по адресу (контракт как у бывшего
\ hmap-key=? в probe: адрес — нижний из четвёрки)
: term-s= ( t type v1 v2 -- flag )
    { tt type v1 v2 }
    tt t-type @ type <> if false exit then
    type TM-STR = if
        v1 v2 tt t-v1 @ tt t-v2 @ compare 0=
    else
        v1 tt t-v1 @ = v2 tt t-v2 @ = and
    then ;

\ ---- копирование и конструкторы ----

: term-copy! ( src dst -- )
    { s d }
    s t-type @ s t-v1 @ s t-v2 @ d term! ;

: t-int!  ( v t -- )  { v t }  TM-INT  v 0  t term! ;
: t-str!  ( p l t -- )  { p l t }  TM-STR p l t term! ;
: t-map!  ( m t -- )  { m t }  TM-MAP  m 0  t term! ;
: t-lst!  ( l t -- )  { l t }  TM-LST  l 0  t term! ;
: t-ptr!  ( a t -- )  { a t }  TM-PTR  a 0  t term! ;
: t-pair! ( k v t -- ) { k v t } TM-PAIR k v t term! ;

\ ---- сравнение порядка (для enum-sort с cmp = 0) ----

\ терм a не позже терма b (a ≤ b). Порядок как в Elixir, в упрощении:
\ сначала тег типа (TM-INT < TM-STR < ...), при равном типе —
\ содержимое: строки посимвольно (compare), остальное по v1, затем v2.
: term-cmp ( a b -- flag )
    { at bt }
    at t-type @ bt t-type @ < if true exit then
    at t-type @ bt t-type @ > if false exit then
    at t-type @ TM-STR = if
        at t-v1 @ at t-v2 @ bt t-v1 @ bt t-v2 @ compare 1 <
    else
        at t-v1 @ bt t-v1 @ < if true exit then
        at t-v1 @ bt t-v1 @ > if false exit then
        at t-v2 @ bt t-v2 @ <=
    then ;
