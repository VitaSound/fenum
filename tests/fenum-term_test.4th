\ tests/fenum-term_test.4th — общий терм-слой fenum:
\ формат [ type v1 v2 ], TM-PTR/TM-PAIR, term!/term@, term=,
\ term-s= (контракт probe hashmap), копирование, конструкторы,
\ term-cmp (порядок термов для enum-sort с cmp = 0).

require ../forth-packages/ttester/1.2.1/ttester.4th
require ../fenum-term.4th

0 #ERRORS !

create tr1  3 cells allot              \ рабочие термы в словаре теста
create tr2  3 cells allot
2variable %ts                          \ литерал строкового значения

cr ." === fenum-term ===" cr

\ ---------- term! / term@ roundtrip ----------
T{ TM-INT 42 0 tr1 term!  tr1 term@ -> 1 42 0 }T
T{ TM-STR 100 7 tr1 term!  tr1 term@ -> 2 100 7 }T
T{ TM-MAP 200 0 tr1 term!  tr1 term@ -> 3 200 0 }T
T{ TM-PTR 300 0 tr1 term!  tr1 term@ -> 5 300 0 }T

\ ---------- term=: равные и неравные ----------
T{ TM-INT 1 0 tr1 term!  TM-INT 1 0 tr2 term!  tr1 tr2 term= -> -1 }T
T{ TM-INT 1 0 tr1 term!  TM-INT 2 0 tr2 term!  tr1 tr2 term= -> 0 }T
\ разных типов не бывает равными даже при равных v1
T{ TM-INT 5 0 tr1 term!  TM-PTR 5 0 tr2 term!  tr1 tr2 term= -> 0 }T
\ строки сравниваются по СОДЕРЖИМОМУ: два разных литерала с одним текстом
T{ TM-STR s" abc" tr1 term!  TM-STR s" abc" tr2 term!  tr1 tr2 term= -> -1 }T
T{ TM-STR s" abc" tr1 term!  TM-STR s" abd" tr2 term!  tr1 tr2 term= -> 0 }T

\ ---------- term-s=: терм со стека против терма по адресу ----------
\ ( контракт как в probe hashmap: адрес — нижний из четвёрки )
T{ TM-INT 9 0 tr1 term!  tr1 TM-INT 9 0 term-s= -> -1 }T
T{ TM-INT 9 0 tr1 term!  tr1 TM-INT 8 0 term-s= -> 0 }T
T{ TM-STR s" zz" tr1 term!  tr1 TM-STR s" zz" term-s= -> -1 }T

\ ---------- term-copy! ----------
T{ TM-INT 7 0 tr1 term!  tr1 tr2 term-copy!  tr2 term@ -> 1 7 0 }T
T{ TM-STR s" copy" tr1 term!  tr1 tr2 term-copy!  tr1 tr2 term= -> -1 }T

\ ---------- конструкторы (адрес терма — последний аргумент) ----------
T{ 5 tr1 t-int!    tr1 term@ -> 1 5 0 }T
T{ 4000 tr1 t-ptr! tr1 term@ -> 5 4000 0 }T
T{ 5000 tr1 t-lst! tr1 term@ -> 4 5000 0 }T
\ строка: адрес/длину кладём в литеральную переменную (адрес предсказуем)
s" key" %ts 2!
T{ %ts 2@ tr1 t-str!  tr1 term@  -> 2 %ts 2@ }T

\ ---------- TM-PAIR (пара термов для enum-sort по map) ----------
T{ TM-PAIR 111 222 tr1 term!  tr1 term@ -> 6 111 222 }T
T{ 4000 5000 tr2 t-pair!  tr2 term@ -> 6 4000 5000 }T

\ ---------- term-cmp (порядок термов, cmp=0 для enum-sort) ----------
\ одинаковые типы: числа численно
T{ TM-INT 1 0 tr1 term!  TM-INT 2 0 tr2 term!  tr1 tr2 term-cmp -> -1 }T
T{ TM-INT 2 0 tr1 term!  TM-INT 1 0 tr2 term!  tr1 tr2 term-cmp -> 0 }T
T{ TM-INT 1 0 tr1 term!  TM-INT 1 0 tr2 term!  tr1 tr2 term-cmp -> -1 }T
\ строки посимвольно, с учётом длины
s" abc" %ts 2!
T{ %ts 2@ tr1 t-str!  s" abd" %ts 2!  %ts 2@ tr2 t-str!
  tr1 tr2 term-cmp -> -1 }T
T{ s" ab" %ts 2!  %ts 2@ tr1 t-str!  s" abc" %ts 2!  %ts 2@ tr2 t-str!
  tr1 tr2 term-cmp -> -1 }T
T{ s" abc" %ts 2!  %ts 2@ tr1 t-str!  s" abc" %ts 2!  %ts 2@ tr2 t-str!
  tr1 tr2 term-cmp -> -1 }T
T{ s" z" %ts 2!  %ts 2@ tr1 t-str!  s" a" %ts 2!  %ts 2@ tr2 t-str!
  tr1 tr2 term-cmp -> 0 }T
\ разные типы: сначала идёт тег (TM-INT < TM-STR)
T{ TM-INT 99 0 tr1 term!  s" zz" %ts 2!  %ts 2@ tr2 t-str!
  tr1 tr2 term-cmp -> -1 }T
T{ s" zz" %ts 2!  %ts 2@ tr1 t-str!  TM-INT 1 0 tr2 term!
  tr1 tr2 term-cmp -> 0 }T
\ v2 — tie-break для нетерминальных типов
T{ TM-PTR 7 5 tr1 term!  TM-PTR 7 3 tr2 term!  tr1 tr2 term-cmp -> 0 }T
T{ TM-PTR 7 3 tr1 term!  TM-PTR 7 5 tr2 term!  tr1 tr2 term-cmp -> -1 }T

cr
#ERRORS @ 0= [IF]
    ." FENUM TERM TEST PASSED" cr
[ELSE]
    ." FENUM TERM TEST FAILED: " #ERRORS @ . cr
[THEN]
bye
