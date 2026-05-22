\ fenum-enum.4th — идентификаторы операций ulist и диспетчер (enum-стиль)
\
\ Константы uop-* можно передавать в ulist-do для единообразного вызова.
\ Прямые слова (ulist-addr@ и т.д.) — в fenum-ulist.4th.

require ./fenum-ulist.4th

0 constant uop-empty?
1 constant uop-addr@
2 constant uop-next@
3 constant uop-len
4 constant uop-reverse
5 constant uop-copy

\ list -- flag
: uop-empty?-exec ( list -- flag )
    ulist-empty? ;

\ list -- addr     (адрес объекта головного узла; 0 если список пуст)
: uop-addr@-exec ( list -- addr )
    dup if ulist-addr@ else drop 0 then ;

\ list -- list
: uop-next@-exec ( list -- list )
    dup if ulist-next@ else drop 0 then ;

\ list -- n
: uop-len-exec ( list -- n )
    ulist-len ;

\ list -- list'
: uop-reverse-exec ( list -- list' )
    ulist-reverse ;

\ list -- list'
: uop-copy-exec ( list -- list' )
    ulist-copy ;

: ulist-do-unknown ( op -- )
    drop ." ulist-do: unknown op" cr abort ;

\ list op -- ...     (только унарные op; bin/xt-вариаций здесь нет)
: ulist-do ( list op -- ... )
    case
        uop-empty?  of uop-empty?-exec  endof
        uop-addr@   of uop-addr@-exec   endof
        uop-next@   of uop-next@-exec   endof
        uop-len     of uop-len-exec     endof
        uop-reverse of uop-reverse-exec endof
        uop-copy    of uop-copy-exec    endof
        ulist-do-unknown
    endcase ;
