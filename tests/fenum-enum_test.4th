require ../forth-packages/ttester/1.1.0/ttester.4th
require ../fenum.4th

\ ---------------------------------------------------------------
\ "Объекты": variables, в .add попадают их адреса.
\ Значения подобраны так, чтобы предикаты были осмысленны.
\ ---------------------------------------------------------------
variable v1   1 v1 !
variable v2   2 v2 !
variable v3   3 v3 !
variable v4   4 v4 !
variable v5   5 v5 !

\ Список (после .add в обратном порядке): 5 -> 4 -> 3 -> 2 -> 1
ulist new value src
v1 src .add
v2 src .add
v3 src .add
v4 src .add
v5 src .add

\ ===============================================================
\ Предикаты / трансформеры / редьюсеры
\ ===============================================================
: even? ( addr -- flag )   @ 1 and 0= ;
: odd?  ( addr -- flag )   @ 1 and 0<> ;
: gt2?  ( addr -- flag )   @ 2 > ;
: pos?  ( addr -- flag )   @ 0> ;
: neg?  ( addr -- flag )   @ 0< ;
: id    ( addr -- addr )   ;
: sum   ( addr acc -- acc' ) swap @ + ;

\ ===============================================================
\ enum-count
\ ===============================================================
T{ src ' even? enum-count                   -> 2 }T   \ 4 и 2
T{ src ' odd?  enum-count                   -> 3 }T   \ 5,3,1
T{ src ' pos?  enum-count                   -> 5 }T
T{ src ' neg?  enum-count                   -> 0 }T

ulist new value empty-c
T{ empty-c ' even? enum-count               -> 0 }T

\ ===============================================================
\ enum-any?
\ ===============================================================
T{ src ' even? enum-any?                    -> true  }T
T{ src ' neg?  enum-any?                    -> false }T
T{ empty-c ' pos? enum-any?                 -> false }T

\ ===============================================================
\ enum-all?
\ ===============================================================
T{ src ' pos?  enum-all?                    -> true  }T
T{ src ' even? enum-all?                    -> false }T
T{ empty-c ' pos? enum-all?                 -> true  }T   \ vacuously true

\ ===============================================================
\ enum-find — первый по порядку обхода (head → tail)
\ src: 5,4,3,2,1; первый чётный = 4
\ ===============================================================
T{ src ' even? enum-find                    -> v4 }T
T{ src ' odd?  enum-find                    -> v5 }T
T{ src ' neg?  enum-find                    -> 0  }T   \ не найдено
T{ empty-c ' pos? enum-find                 -> 0  }T

\ ===============================================================
\ enum-reduce — сумма всех значений
\ ===============================================================
T{ src 0   ' sum enum-reduce                -> 15 }T   \ 5+4+3+2+1
T{ src 100 ' sum enum-reduce                -> 115 }T
T{ empty-c 42 ' sum enum-reduce             -> 42 }T

\ ===============================================================
\ enum-filter — новый ulist с сохранением порядка
\ ===============================================================
src ' gt2? enum-filter value filtered
T{ filtered .len                            -> 3   }T
T{ 0 filtered .nth-addr                     -> v5  }T   \ порядок как у src
T{ 1 filtered .nth-addr                     -> v4  }T
T{ 2 filtered .nth-addr                     -> v3  }T
filtered .dispose

\ исходник не изменён
T{ src .len                                 -> 5   }T
T{ 0 src .nth-addr                          -> v5  }T

\ filter на пустом
T{ empty-c ' even? enum-filter dup .len swap .dispose -> 0 }T

\ ===============================================================
\ enum-map — новый ulist той же длины
\ ===============================================================
src ' id enum-map value mapped
T{ mapped .len                              -> 5   }T
T{ 0 mapped .nth-addr                       -> v5  }T
T{ 4 mapped .nth-addr                       -> v1  }T
mapped .dispose

T{ empty-c ' id enum-map dup .len swap .dispose -> 0 }T

\ ===============================================================
\ Полиморфизм: универсальная функция filter-positive
\ работает с любым container.
\ ===============================================================
: positive-only ( c -- c' ) ['] pos? enum-filter ;
src positive-only value pp
T{ pp .len                                  -> 5 }T
pp .dispose

empty-c .dispose
src .dispose
