\ fenum-enum-core.4th — enum-each / enum-sort (без require backend)
\
\ Backend (struct.fs или begin-structure) должен быть загружен раньше:
\ container%, ulist-*, TYPE_ULIST, obj-type @.

[IFDEF] enum-each [ELSE]

: %enum-unknown ( type -- )
    drop ." fenum-enum: unknown container type" cr abort ;

: enum-each ( xt c -- )
    dup obj-type @ case
        TYPE_ULIST of ulist-each endof
        %enum-unknown
    endcase ;

variable %sort-array
variable %sort-n
variable %sort-idx
variable %sort-cmp-xt

: %sort-collect ( addr -- )
    %sort-array @ %sort-idx @ cells + !
    1 %sort-idx +! ;

: %sort-at ( i -- value )
    cells %sort-array @ + @ ;

: %sort-at! ( value i -- )
    cells %sort-array @ + ! ;

: %sort-swap ( i j -- )
    over %sort-at over %sort-at
    3 roll
    %sort-at!
    swap %sort-at! ;

: %sort-cmp ( i j -- flag )
    %sort-at swap %sort-at swap
    %sort-cmp-xt @ execute ;

: %sort-bubble ( n -- )
    dup 2 < if drop exit then
    dup 0 ?do
        dup 1- 0 ?do
            I I 1+ %sort-cmp 0= if
                I I 1+ %sort-swap
            then
        loop
    loop
    drop ;

: %sort-to-ulist ( -- new-ulist )
    ulist-new
    %sort-n @ 0 ?do
        %sort-array @
        %sort-n @ 1- I -  cells +
        @
        over ulist-add
    loop ;

: enum-sort ( xt c -- new-ulist )
    dup obj-type @ case
        TYPE_ULIST of endof
        %enum-unknown
    endcase
    swap %sort-cmp-xt !
    dup ulist-len dup %sort-n !
    0= if drop ulist-new exit then
    %sort-n @ cells allocate throw %sort-array !
    0 %sort-idx !
    ['] %sort-collect swap enum-each
    %sort-n @ %sort-bubble
    %sort-to-ulist
    %sort-array @ free throw ;

[THEN]
