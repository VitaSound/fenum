\ tests/fenum-hmap_test.4th — хеш-мапа: любые типы значений (тег TM-*),
\ вложенность map-в-map (как в Elixir), пересборка пула при del,
\ обход каждый/enum-each, переполнение, clear/dispose.

require ../forth-packages/ttester/1.2.1/ttester.4th
require ./fenum-test-common.4th

variable hm1  variable hm2  variable hm3  variable hm4  variable hm5
variable hsum
2variable %sv                              \ строка-значение для теста

: hm-fresh ( addr -- ) hashmap-new swap ! ;

\ xt для обхода: сумма TM-INT-значений
: %hmsum ( slot -- )
    dup hmap-vt @ TM-INT = if
        dup hmap-v1 @ hsum +!          \ второй dup: hmap-v1 снимает свой аргумент
    then
    drop ;

\ 20 строковых-ключей -> int (ключ i, значение i); сумма 1..20 = 210
: %fill20 ( m -- )
    { m } 21 1 ?do TM-INT i 0 TM-INT i 0 m hashmap-set loop ;

\ 130 вставок в кап-128: одна должна упасть throw'ом
: %hmbigfill ( m -- )
    { m } 131 1 ?do TM-INT i 0 TM-INT i 0 m hashmap-set loop ;
: %hmbigfill-full? ( m -- flag )            \ true = переполнение поймано
    ['] %hmbigfill catch if drop true else drop false then ;

s" seven" %sv 2!                             \ литерал в (ptr,len)

cr ." === fenum-hashmap ===" cr

\ ---------- базовое ----------
T{ hm1 hm-fresh  hm1 @ hashmap-empty? -> -1 }T
T{ hm1 @ hashmap-len -> 0 }T
T{ hm1 @ obj-type @ -> TYPE_HASHMAP }T

\ ---------- строковый ключ / int-значение (полный терм) ----------
T{
  TM-STR s" alpha" TM-INT 42 0  hm1 @ hashmap-set
  TM-STR s" alpha" hm1 @ hashmap-get
-> 1 42 0 -1 }T
T{ TM-STR s" alpha" hm1 @ hashmap-has? -> -1 }T
T{ TM-STR s" nope" hm1 @ hashmap-has? -> 0 }T
T{ TM-STR s" nope" hm1 @ hashmap-get -> 0 0 0 0 }T
T{ hm1 @ hashmap-len -> 1 }T

\ ---------- перезапись: счётчик не растёт ----------
T{
  TM-STR s" alpha" TM-INT 43 0  hm1 @ hashmap-set
  TM-STR s" alpha" hm1 @ hashmap-get
-> 1 43 0 -1 }T
T{ hm1 @ hashmap-len -> 1 }T

\ ---------- int-ключ / строковое-значение (типы любые) ----------
T{
  hm1 @ hashmap-dispose  hm1 hm-fresh
  TM-INT 9 0 TM-STR %sv 2@  hm1 @ hashmap-set
  TM-INT 9 0 hm1 @ hashmap-get
-> 2 %sv 2@ -1 }T

\ ---------- вложенность: мапа как значение (map-в-map) ----------
T{
  hm2 hm-fresh
  TM-STR s" child" TM-MAP hm2 @ 0  hm1 @ hashmap-set
  TM-STR s" child" hm1 @ hashmap-get
-> 3 hm2 @ 0 -1 }T
\ и по адресу-значению реально работаем (дочерняя мапа живая)
T{
  TM-STR s" beta" TM-INT 7 0  hm2 @ hashmap-set
  TM-STR s" beta" hm2 @ hashmap-get
-> 1 7 0 -1 }T

\ ---------- пересборка при del: остальные ключи живы ----------
T{
  hm3 hm-fresh
  TM-STR s" a" TM-INT 1 0   hm3 @ hashmap-set
  TM-STR s" b" TM-INT 10 0  hm3 @ hashmap-set
  TM-STR s" c" TM-INT 100 0 hm3 @ hashmap-set
  TM-STR s" a" hm3 @ hashmap-del
-> -1 }T
T{ TM-STR s" a" hm3 @ hashmap-has? -> 0 }T
T{ TM-STR s" b" hm3 @ hashmap-get -> 1 10 0 -1 }T
T{ TM-STR s" c" hm3 @ hashmap-get -> 1 100 0 -1 }T
T{ hm3 @ hashmap-len -> 2 }T

\ ---------- каждый (xt: slot) и enum-each по TYPE_HASHMAP ----------
\ примечание: mап-цепочку (каждый/enum-each) вызываем ВНЕ T{}: внутри
\ T{} вызов слова, содержащего mап-обход, даёт segfault (ttester-контекст);
\ поэтому здесь в T{} — только подготовка и проверка значений.
\ В колонных определениях — только ['] (tick в колонке парсит имя при
\ выполнении, в T{} — как в тестах ulist: ')
: %each4 ( -- ) ['] %hmsum hm4 @ hashmap-each ;
: %enum4 ( -- ) ['] %hmsum hm4 @ enum-each ;
T{ hm4 hm-fresh -> }T
T{ hm4 @ %fill20 -> }T
T{ hm4 @ hashmap-len -> 20 }T
0 hsum !
%each4
T{ hsum @ -> 210 }T
0 hsum !
%enum4
T{ hsum @ -> 210 }T

\ ---------- clear ----------
T{ hm4 @ hashmap-clear  hm4 @ hashmap-len  hm4 @ hashmap-empty? -> 0 -1 }T

\ ---------- переполнение (cap=128, вставка 129-й — throw) ----------
T{ hm5 hm-fresh  hm5 @ %hmbigfill-full? -> -1 }T

\ ---------- dispose всех ----------
T{
  hm1 @ hashmap-dispose  hm2 @ hashmap-dispose
  hm3 @ hashmap-dispose  hm4 @ hashmap-dispose
  hm5 @ hashmap-dispose
-> }T

cr
#ERRORS @ 0= [IF]
    ." FENUM HASHMAP TEST PASSED" cr
[ELSE]
    ." FENUM HASHMAP TEST FAILED: " #ERRORS @ . cr
[THEN]
bye
