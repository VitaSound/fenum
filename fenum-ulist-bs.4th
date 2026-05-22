\ fenum-ulist-bs.4th — ulist на begin-structure (без struct.fs)
\
\ Тот же публичный API, что fenum-ulist.4th. Стек-конвенции те же.
\ Поля struct.fs: ( struct value ) для !; begin-structure: ( value struct ).

[IFDEF] ulist-new [ELSE]

require ./fenum-types.4th

begin-structure ulist%
    field: obj-type
    field: ulist-head
end-structure

begin-structure unode%
    field: unode-addr
    field: unode-next
end-structure

variable unode-new-tmp
variable ulist-new-tmp

: unode-new ( addr next -- node )
    unode% allocate throw unode-new-tmp !
    swap unode-new-tmp @ unode-addr !
    unode-new-tmp @ unode-next !
    unode-new-tmp @ ;

: unode-chain-len ( chain -- n )
    0 swap
    begin dup while
        swap 1+ swap unode-next @
    repeat drop ;

: unode-chain-each ( chain xt -- )
    >r begin dup while
        dup unode-addr @ r@ execute unode-next @
    repeat drop rdrop ;

: unode-chain-find ( chain addr -- node|0 )
    >r begin
        dup while
            dup unode-addr @ r@ = if rdrop exit then
            unode-next @
        repeat
        rdrop ;

: unode-chain-nth ( chain n -- node|0 )
    dup 0< if 2drop 0 exit then
    0 ?do
        dup 0= if unloop exit then
        unode-next @
    loop ;

: unode-chain-free ( chain -- )
    begin dup while
        dup unode-next @ swap free throw
    repeat drop ;

: unode-chain-reverse ( chain -- chain' )
    0 swap
    begin dup while
        dup unode-next @
        -rot
        2dup unode-next !
        nip swap
    repeat
    drop ;

: ulist-new ( -- lst )
    ulist% allocate throw ulist-new-tmp !
    TYPE_ULIST ulist-new-tmp @ obj-type !
    0 ulist-new-tmp @ ulist-head !
    ulist-new-tmp @ ;

: ulist-empty? ( lst -- flag )
    ulist-head @ 0= ;

: ulist-len ( lst -- n )
    ulist-head @ unode-chain-len ;

: ulist-add ( addr lst -- )
    dup >r
    ulist-head @
    unode-new
    r> ulist-head ! ;

: ulist-contains? ( addr lst -- flag )
    ulist-head @ swap
    unode-chain-find 0<> ;

: ulist-nth-addr ( n lst -- addr|0 )
    ulist-head @ swap
    unode-chain-nth
    dup if unode-addr @ then ;

: ulist-each ( xt lst -- )
    ulist-head @ swap
    unode-chain-each ;

: ulist-reverse ( lst -- )
    dup ulist-head @ unode-chain-reverse
    swap ulist-head ! ;

: ulist-clear ( lst -- )
    dup ulist-head @ unode-chain-free
    0 swap ulist-head ! ;

: ulist-dispose ( lst -- )
    dup ulist-head @ unode-chain-free
    free throw ;

[THEN]
