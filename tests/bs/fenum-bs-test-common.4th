\ Фикстуры для bs-тестов. Требует чистый образ (без require ./fenum.4th).

[IFDEF] fenum-backend-struct [IF]
cr ." fenum-bs: struct.fs backend already loaded" cr
abort
[THEN] [THEN]

require ../../fenum-bs.4th

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
