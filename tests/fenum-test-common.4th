\ Общие фикстуры и хелперы для fenum-тестов.
\ Подключать один раз из каждого test-файла.

require ../fenum.4th

variable v10   10 v10 !
variable v20   20 v20 !
variable v30   30 v30 !
variable v40   40 v40 !

variable %tl
variable %tl2
variable %sum

: mk-tl ( -- )    ulist-new %tl ! ;
: rm-tl ( -- )    %tl @ ulist-dispose ;
: rm-tl2 ( -- )   %tl2 @ ulist-dispose ;

: %add-to-sum ( addr -- ) @ %sum +! ;
