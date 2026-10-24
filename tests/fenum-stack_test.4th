\ fenum-stack_test.4th — регрессионный тест фикса утечки data stack
\
\ Фикс: структуры закрываются end-struct (container% — 2constant для
\ пары расширения) и end-struct-const (ulist%/unode% — константа-размер
\ одной ячейкой). Раньше обычный constant снимал только size, и align
\ struct-протокола утекал в data stack при require — после загрузки
\ fenum стек оставался с <2> 8 8.
\
\ Тест фиксирует: после require fenum глубина data stack не изменилась.

require ../forth-packages/ttester/1.2.1/ttester.4th

variable depth0
depth depth0 !

require ../fenum.4th

\ утечка = разница глубины до и после require
T{ depth depth0 @ - -> 0 }T

\ семантика размеров сохранилась: anode%/ulist% — 16, nd-size (терм-узел) — 32,
\ container% — пара ( align size ) для расширения структуры
T{ anode% -> 16 }T
T{ nd-size -> 32 }T
T{ ulist%  -> 16 }T
T{ container% -> 8 8 }T

\ allocate-семантика: unode-new отработал и вернул стек в чистоту
T{
  depth depth0 !
  11 22 anode-new drop
  depth depth0 @ -
-> 0 }T

cr
#ERRORS @ 0= [IF]
    ." FENUM STACK TEST PASSED" cr
[ELSE]
    ." FENUM STACK TEST FAILED: " #ERRORS @ . cr
[THEN]
bye
