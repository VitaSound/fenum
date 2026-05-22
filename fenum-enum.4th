\ fenum-enum.4th — функции высшего порядка над container (Elixir.Enum-стиль)
\
\ Все функции работают через интерфейс container: .each + .new-empty + .add
\ + .reverse, поэтому полиморфны по контейнеру.
\
\ Возвращающие новый контейнер (filter/map) делают .new-empty + .add в голову,
\ потом .reverse — чтобы порядок совпадал с порядком итерации исходного
\ контейнера. Для container'ов без порядка (.reverse = noop) post-reverse
\ ничего не ломает.

require ./fenum-container.4th

\ ---- внутренние слоты, в которые временно передаются closure-данные ----
\ Forth не имеет настоящих closure; кладём xt и аккумулятор в variable.
\ Слова enum-* не реентерабельны (нельзя вложенно map/filter одновременно),
\ что для обычного использования из обычного кода нормально.

variable %enum-xt
variable %enum-target
variable %enum-acc
variable %enum-counter
variable %enum-found
variable %enum-flag

\ ===============================================================
\ count ( c xt -- n )       ; xt: ( addr -- flag )
\ ===============================================================
: %count-step ( addr -- )
    %enum-xt @ execute if 1 %enum-counter +! then ;

: enum-count ( c xt -- n )
    %enum-xt !
    0 %enum-counter !
    ['] %count-step swap .each
    %enum-counter @ ;

\ ===============================================================
\ any? ( c xt -- flag )     ; true если хотя бы для одного xt → true
\ ===============================================================
: %any-step ( addr -- )
    %enum-flag @ if drop exit then
    %enum-xt @ execute if true %enum-flag ! then ;

: enum-any? ( c xt -- flag )
    %enum-xt !
    false %enum-flag !
    ['] %any-step swap .each
    %enum-flag @ ;

\ ===============================================================
\ all? ( c xt -- flag )     ; true если для всех xt → true
\ ===============================================================
: %all-step ( addr -- )
    %enum-flag @ 0= if drop exit then
    %enum-xt @ execute 0= if false %enum-flag ! then ;

: enum-all? ( c xt -- flag )
    %enum-xt !
    true %enum-flag !
    ['] %all-step swap .each
    %enum-flag @ ;

\ ===============================================================
\ find ( c xt -- addr|0 )   ; первый addr, для которого xt → true
\ ===============================================================
: %find-step ( addr -- )
    %enum-found @ if drop exit then
    dup %enum-xt @ execute
    if %enum-found ! else drop then ;

: enum-find ( c xt -- addr|0 )
    %enum-xt !
    0 %enum-found !
    ['] %find-step swap .each
    %enum-found @ ;

\ ===============================================================
\ reduce ( c acc xt -- acc' )   ; xt: ( addr acc -- acc' )
\ ===============================================================
: %reduce-step ( addr -- )
    %enum-acc @ %enum-xt @ execute %enum-acc ! ;

: enum-reduce ( c acc xt -- acc' )
    %enum-xt !
    %enum-acc !
    ['] %reduce-step swap .each
    %enum-acc @ ;

\ ===============================================================
\ filter ( c xt -- c' )    ; новый контейнер того же типа
\ ===============================================================
: %filter-step ( addr -- )
    dup %enum-xt @ execute
    if   %enum-target @ .add
    else drop
    then ;

: enum-filter ( c xt -- c' )
    %enum-xt !
    dup .new-empty %enum-target !
    ['] %filter-step swap .each
    %enum-target @ dup .reverse ;

\ ===============================================================
\ map ( c xt -- c' )       ; xt: ( addr -- addr' ); новый контейнер
\ ===============================================================
: %map-step ( addr -- )
    %enum-xt @ execute
    %enum-target @ .add ;

: enum-map ( c xt -- c' )
    %enum-xt !
    dup .new-empty %enum-target !
    ['] %map-step swap .each
    %enum-target @ dup .reverse ;
