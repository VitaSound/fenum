require ../forth-packages/ttester/1.2.1/ttester.4th
require ./fenum-test-common.4th

: %asc  ( a b -- flag )   swap @ swap @ <= ;
: %desc ( a b -- flag )   swap @ swap @ >= ;

\ ===== фикстуры этапа 4: термовый ulist и hashmap =====
variable %te                              \ термовый список
variable %hm4e                            \ тестируемая мапа
variable %pm                              \ упорядоченные пары (результат sort)
variable %lvar                            \ результат leak-проверки

: mk-ul ( -- )  ulist-new %te ! ;
: rm-ul2 ( -- )  %tl2 @ ulist-dispose ;   \ результат sort термового списка
: rm-ul ( -- )  %te @ ulist-dispose ;
: mk-hm ( -- )  hashmap-new %hm4e ! ;
: rm-hm ( -- )  %hm4e @ hashmap-dispose ;
: rm-pm ( -- )  %pm @ ulist-dispose ;
: sort-hm ( cmp-xt -- )  %hm4e @ enum-sort %pm ! ;

\ пользовательский cmp для ТЕРМОВОГО списка: убывание по TM-INT
: %tdesc ( a b -- flag )  swap t-v1 @ swap t-v1 @ >= ;
\ пользовательский cmp для map: ключи по убыванию (слот = ключ-терм)
: %kdesc ( a b -- flag )  swap term-cmp ;

\ помощники чтения результата map-сортировки
: pm-key ( n lst -- kv1 kv2 )     ulist-nth-term drop nip term@ rot drop ;
: pm-val ( n lst -- v )           ulist-nth-term nip nip term@ drop nip ;

\ xt для leak-проверки: просто снимает слот
: %slotdrop ( slot -- )  drop ;
variable %d0
: %hleak ( -- n )
    depth %d0 !  ['] %slotdrop %hm4e @ hashmap-each  depth %d0 @ - ;

\ ============== enum-each идентичен addrlist-each =========
T{
  0 %sum !
  mk-tl
  v10 %tl @ addrlist-add  v20 %tl @ addrlist-add  v30 %tl @ addrlist-add
  ' %add-to-sum %tl @ enum-each
  rm-tl
  %sum @
-> 60 }T

\ enum-each на пустом — не зовёт xt
T{
  0 %sum !
  mk-tl
  ' %add-to-sum %tl @ enum-each
  rm-tl
  %sum @
-> 0 }T

\ ============== enum-sort ascending ====================
\ Было head→tail: v30 v20 v10.  Sorted ascending: v10 v20 v30.
T{
  mk-tl
  v10 %tl @ addrlist-add  v20 %tl @ addrlist-add  v30 %tl @ addrlist-add
  ' %asc %tl @ enum-sort %tl2 !
  0 %tl2 @ addrlist-nth-addr
  1 %tl2 @ addrlist-nth-addr
  2 %tl2 @ addrlist-nth-addr
  rm-tl  rm-tl2
-> v10 v20 v30 }T

\ ============== enum-sort descending ===================
T{
  mk-tl
  v10 %tl @ addrlist-add  v20 %tl @ addrlist-add  v30 %tl @ addrlist-add
  ' %desc %tl @ enum-sort %tl2 !
  0 %tl2 @ addrlist-nth-addr
  1 %tl2 @ addrlist-nth-addr
  2 %tl2 @ addrlist-nth-addr
  rm-tl  rm-tl2
-> v30 v20 v10 }T

\ ============== enum-sort пустого ======================
T{
  mk-tl
  ' %asc %tl @ enum-sort %tl2 !
  %tl2 @ addrlist-empty?
  %tl2 @ addrlist-len
  rm-tl  rm-tl2
-> -1 0 }T

\ ============== enum-sort не меняет исходник ===========
T{
  mk-tl
  v10 %tl @ addrlist-add  v20 %tl @ addrlist-add  v30 %tl @ addrlist-add
  ' %asc %tl @ enum-sort %tl2 !
  0 %tl  @ addrlist-nth-addr          \ исходник: head=v30
  0 %tl2 @ addrlist-nth-addr          \ sorted: head=v10
  %tl @ addrlist-len
  rm-tl  rm-tl2
-> v30 v10 3 }T

\ ============== enum-sort на одном элементе ============
T{
  mk-tl
  v10 %tl @ addrlist-add
  ' %asc %tl @ enum-sort %tl2 !
  %tl2 @ addrlist-len
  0 %tl2 @ addrlist-nth-addr
  rm-tl  rm-tl2
-> 1 v10 }T

\ ============================================================
\ Этап 4: cmp как HOF (адрес слова) + cmp = 0 (дефолт)
\ ============================================================

\ ---- addrlist: cmp = 0 → содержимое ячейки численно ----
T{
  mk-tl
  v10 %tl @ addrlist-add  v30 %tl @ addrlist-add  v20 %tl @ addrlist-add
  0 %tl @ enum-sort %tl2 !
  0 %tl2 @ addrlist-nth-addr
  1 %tl2 @ addrlist-nth-addr
  2 %tl2 @ addrlist-nth-addr
  rm-tl  rm-tl2
-> v10 v20 v30 }T

\ ============ ТЕРМОВЫЙ ulist (TYPE_ULIST) ============

\ enum-each на термовом списке (dispatch после разделения типов)
: %tsum ( term-addr -- )  t-v1 @ %sum +! ;
T{
  0 %sum !
  mk-ul
  TM-INT 3 0 %te @ ulist-add  TM-INT 4 0 %te @ ulist-add
  ' %tsum %te @ enum-each
  rm-ul
  %sum @
-> 7 }T

\ default sort (cmp = 0 → term-cmp): числа по возрастанию
T{
  mk-ul
  TM-INT 5 0 %te @ ulist-add  TM-INT 1 0 %te @ ulist-add  TM-INT 3 0 %te @ ulist-add
  0 %te @ enum-sort %tl2 !
  0 %tl2 @ ulist-nth-term drop nip
  1 %tl2 @ ulist-nth-term drop nip
  2 %tl2 @ ulist-nth-term drop nip
  rm-ul  rm-ul2
-> 1 3 5 }T

\ пользовательский cmp (%tdesc): убывание
T{
  mk-ul
  TM-INT 5 0 %te @ ulist-add  TM-INT 1 0 %te @ ulist-add  TM-INT 3 0 %te @ ulist-add
  ' %tdesc %te @ enum-sort %tl2 !
  0 %tl2 @ ulist-nth-term drop nip
  1 %tl2 @ ulist-nth-term drop nip
  2 %tl2 @ ulist-nth-term drop nip
  rm-ul  rm-ul2
-> 5 3 1 }T

\ строки default: посимвольно
T{
  mk-ul
  TM-STR s" b" %te @ ulist-add  TM-STR s" a" %te @ ulist-add
  0 %te @ enum-sort %tl2 !
  0 %tl2 @ ulist-nth-term rot drop s" a" compare 0=
  1 %tl2 @ ulist-nth-term rot drop s" b" compare 0=
  rm-ul  rm-ul2
-> -1 -1 }T

\ смешанные типы: TM-INT (тег 1) перед TM-STR (тег 2)
T{
  mk-ul
  TM-STR s" zz" %te @ ulist-add
  TM-INT 7 0 %te @ ulist-add
  0 %te @ enum-sort %tl2 !
  0 %tl2 @ ulist-nth-term drop nip
  1 %tl2 @ ulist-nth-term rot drop s" zz" compare 0=
  rm-ul  rm-ul2
-> 7 -1 }T

\ пустой термовый список
T{
  mk-ul
  0 %te @ enum-sort %tl2 !
  %tl2 @ ulist-empty?
  %tl2 @ ulist-len
  rm-ul  rm-ul2
-> -1 0 }T

\ исходник не мутируется (prepend-порядок против sorted)
T{
  mk-ul
  TM-INT 3 0 %te @ ulist-add  TM-INT 1 0 %te @ ulist-add  TM-INT 2 0 %te @ ulist-add
  0 %te @ enum-sort %tl2 !
  0 %te  @ ulist-nth-term drop nip        \ исходник: head = 2
  0 %tl2 @ ulist-nth-term drop nip        \ sorted: первый = 1
  %te @ ulist-len
  rm-ul  rm-ul2
-> 2 1 3 }T

\ ============ HASHMAP: сортировка ПО КЛЮЧАМ (Elixir) ============
\ mап-обходы (sort-hm) — ВНЕ T{} (см. fenum-hmap_test: mап-цепочка
\ внутри T{} даёт segfault); в T{} — подготовка и проверка чтением.

\ ---- default: ключи a,b,c по возрастанию, значения в их порядке ----
T{
  mk-hm
  TM-STR s" b" TM-INT 20 0 %hm4e @ hashmap-set
  TM-STR s" a" TM-INT 10 0 %hm4e @ hashmap-set
  TM-STR s" c" TM-INT 30 0 %hm4e @ hashmap-set
  %hm4e @ hashmap-len -> 3 }T
0 sort-hm
T{
  %pm @ ulist-len
  0 %pm @ pm-key s" a" compare 0=
  1 %pm @ pm-key s" b" compare 0=
  2 %pm @ pm-key s" c" compare 0=
  0 %pm @ pm-val
  1 %pm @ pm-val
  2 %pm @ pm-val
  rm-pm  rm-hm
-> 3 -1 -1 -1 10 20 30 }T

\ ---- пользовательский cmp (%kdesc): ключи по убыванию ----
T{
  mk-hm
  TM-STR s" b" TM-INT 20 0 %hm4e @ hashmap-set
  TM-STR s" a" TM-INT 10 0 %hm4e @ hashmap-set
  TM-STR s" c" TM-INT 30 0 %hm4e @ hashmap-set
  %hm4e @ hashmap-len -> 3 }T
' %kdesc sort-hm
T{
  0 %pm @ pm-key s" c" compare 0=
  2 %pm @ pm-key s" a" compare 0=
  0 %pm @ pm-val
  rm-pm  rm-hm
-> -1 -1 30 }T

\ ---- пустая мапа → пустой список пар ----
T{ mk-hm -> }T
0 sort-hm
T{
  %pm @ ulist-empty?
  %pm @ ulist-len
  rm-pm  rm-hm
-> -1 0 }T

\ ---- hashmap-each не течёт стеком (пустые слоты снимаются) ----
T{
  mk-hm
  TM-STR s" x" TM-INT 1 0 %hm4e @ hashmap-set
  TM-STR s" y" TM-INT 2 0 %hm4e @ hashmap-set
  %hm4e @ hashmap-len -> 2 }T
%hleak %lvar !
T{ %lvar @  rm-hm -> 0 }T
