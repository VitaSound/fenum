\ tests/fenum-ulist_test.4th — универсальный список ТЕРМОВ:
\ элемент = терм любого типа (TM-INT/STR/MAP/PTR), порядок prepend,
\ contains-term?, обход xt ( term-addr ), reverse/clear/dispose,
\ вложенность: мапа как элемент списка (как в Elixir list of maps).

require ../forth-packages/ttester/1.2.1/ttester.4th
require ./fenum-test-common.4th

0 #ERRORS !

variable %ul   variable %ul2   variable %hm   variable %cnt
2variable %us                              \ литерал строкового элемента
s" text" %us 2!

: ul-fresh ( -- ) ulist-new %ul ! ;
: rm-ul ( -- ) %ul @ ulist-dispose ;

\ xt обхода: счётчик элементов
: %cnt-e ( t -- ) 1 %cnt +! drop ;

cr ." === fenum-ulist (термы) ===" cr

\ ---------- базовое ----------
T{ ul-fresh %ul @ ulist-empty? -> -1 }T
T{ %ul @ ulist-len -> 0 }T
T{ %ul @ obj-type @ -> TYPE_ULIST }T

\ ---------- prepend: голова = последний добавленный ----------
T{
  ul-fresh
  TM-INT 10 0 %ul @ ulist-add
  TM-INT 20 0 %ul @ ulist-add
  0 %ul @ ulist-nth-term
-> 1 20 0 }T
T{ 1 %ul @ ulist-nth-term -> 1 10 0 }T
T{ 2 %ul @ ulist-nth-term -> 0 0 0 }T     \ вне диапазона
T{ %ul @ ulist-len -> 2 }T

\ ---------- элементы любых типов в одном списке ----------
\ порядок добавления: INT → STR → PTR; голова = PTR
T{
  ul-fresh
  TM-INT 1 0    %ul @ ulist-add
  TM-STR %us 2@ %ul @ ulist-add
  TM-PTR 99 0   %ul @ ulist-add
  0 %ul @ ulist-nth-term
-> 5 99 0 }T
T{ 1 %ul @ ulist-nth-term -> 2 %us 2@ }T
T{ 2 %ul @ ulist-nth-term -> 1 1 0 }T

\ ---------- contains-term? (строки — по содержимому) ----------
T{
  ul-fresh
  TM-INT 7 0 %ul @ ulist-add
  TM-STR %us 2@ %ul @ ulist-add
  TM-INT 7 0 %ul @ ulist-contains-term?
-> -1 }T
T{ TM-INT 8 0 %ul @ ulist-contains-term? -> 0 }T
\ другой литерал с тем же текстом — всё равно равен (compare)
T{ TM-STR s" text" %ul @ ulist-contains-term? -> -1 }T

\ ---------- обход: каждый элемент как term-addr ----------
T{
  ul-fresh
  TM-INT 1 0 %ul @ ulist-add
  TM-INT 2 0 %ul @ ulist-add
  TM-INT 3 0 %ul @ ulist-add
  0 %cnt !  ' %cnt-e %ul @ ulist-each  %cnt @
-> 3 }T

\ ---------- reverse (in-place) ----------
T{
  ul-fresh
  TM-INT 10 0 %ul @ ulist-add
  TM-INT 20 0 %ul @ ulist-add
  %ul @ ulist-reverse
  0 %ul @ ulist-nth-term
-> 1 10 0 }T

\ ---------- clear: список остаётся валидным пустым ----------
T{
  ul-fresh
  TM-INT 5 0 %ul @ ulist-add
  %ul @ ulist-clear
  %ul @ ulist-len  %ul @ ulist-empty?
-> 0 -1 }T

\ ---------- вложенность: мапа как элемент списка ----------
\ (адрес мапы, взятый из элемента-терма, реально работает)
: %elm ( ul -- v1 ) 0 swap ulist-nth-term rot drop drop ;
T{ ul-fresh -> }T
T{ hashmap-new %hm ! -> }T
T{ TM-MAP %hm @ 0 %ul @ ulist-add -> }T
T{ %ul @ %elm %hm @ = -> -1 }T
T{ TM-STR s" k" TM-INT 7 0 %hm @ hashmap-set -> }T
T{ TM-STR s" k" %hm @ hashmap-get -> 1 7 0 -1 }T
T{ %hm @ hashmap-dispose -> }T

\ ---------- dispose ----------
T{
  ul-fresh
  TM-INT 1 0 %ul @ ulist-add
  rm-ul
-> }T

cr
#ERRORS @ 0= [IF]
    ." FENUM ULIST TEST PASSED" cr
[ELSE]
    ." FENUM ULIST TEST FAILED: " #ERRORS @ . cr
[THEN]
bye
