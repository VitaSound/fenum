require ../forth-packages/ttester/1.1.0/ttester.4th
require ../fenum-ulist.4th
require ../fenum-enum.4th

\ ---------------------------------------------------------------
\ Test objects (просто variable как «объекты», их адреса попадут в list)
\ ---------------------------------------------------------------
variable obj-a  100 obj-a !
variable obj-b  200 obj-b !
variable obj-c  300 obj-c !
variable obj-d  400 obj-d !
variable obj-x  999 obj-x !

\ ===============================================================
\ ulist-null / ulist-empty?
\ ===============================================================
T{ ulist-null                   -> 0     }T
T{ ulist-null ulist-empty?      -> true  }T

\ ===============================================================
\ ulist-node: построение вручную, проверка полей
\ ===============================================================
obj-c ulist-null ulist-node value node-c
obj-b node-c     ulist-node value node-b
obj-a node-b     ulist-node value node-a

T{ node-a ulist-empty?              -> false }T
T{ node-a ulist-addr@               -> obj-a }T
T{ node-a ulist-next@               -> node-b }T
T{ node-b ulist-addr@               -> obj-b }T
T{ node-b ulist-next@               -> node-c }T
T{ node-c ulist-addr@               -> obj-c }T
T{ node-c ulist-next@               -> 0      }T

\ ===============================================================
\ ulist-addr! / ulist-next!  (мутация поля)
\ ===============================================================
node-a obj-x ulist-addr!
T{ node-a ulist-addr@               -> obj-x }T
node-a obj-a ulist-addr!
T{ node-a ulist-addr@               -> obj-a }T

\ ===============================================================
\ ulist-len
\ ===============================================================
T{ ulist-null ulist-len             -> 0 }T
T{ node-c     ulist-len             -> 1 }T
T{ node-b     ulist-len             -> 2 }T
T{ node-a     ulist-len             -> 3 }T

\ ===============================================================
\ ulist-cons (порядок: cons кладёт addr в голову)
\ ===============================================================
obj-d ulist-null ulist-cons
obj-c swap       ulist-cons
obj-b swap       ulist-cons
obj-a swap       ulist-cons value cons-list

T{ cons-list ulist-len              -> 4 }T
T{ cons-list                  ulist-addr@ -> obj-a }T
T{ cons-list ulist-next@      ulist-addr@ -> obj-b }T
T{ cons-list ulist-next@ ulist-next@ ulist-addr@ -> obj-c }T

\ ===============================================================
\ ulist-nth / ulist-nth-addr
\ ===============================================================
T{ cons-list 0 ulist-nth-addr       -> obj-a }T
T{ cons-list 1 ulist-nth-addr       -> obj-b }T
T{ cons-list 2 ulist-nth-addr       -> obj-c }T
T{ cons-list 3 ulist-nth-addr       -> obj-d }T
T{ cons-list 4 ulist-nth            -> 0 }T
T{ cons-list 4 ulist-nth-addr       -> 0 }T
T{ cons-list -1 ulist-nth           -> 0 }T
T{ cons-list -1 ulist-nth-addr      -> 0 }T
T{ ulist-null 0 ulist-nth           -> 0 }T
T{ ulist-null 5 ulist-nth           -> 0 }T

\ ===============================================================
\ ulist-find-addr / ulist-contains?
\ ===============================================================
T{ cons-list obj-a ulist-find-addr  ulist-addr@ -> obj-a }T
T{ cons-list obj-d ulist-find-addr  ulist-addr@ -> obj-d }T
T{ cons-list obj-x ulist-find-addr  -> 0 }T
T{ ulist-null obj-a ulist-find-addr -> 0 }T

T{ cons-list obj-a ulist-contains?  -> true  }T
T{ cons-list obj-x ulist-contains?  -> false }T
T{ ulist-null obj-a ulist-contains? -> false }T

\ ===============================================================
\ ulist-for-each: проверим, что xt вызывается для каждого addr
\ ===============================================================
variable foreach-sum   0 foreach-sum !
: foreach-add ( addr -- ) @ foreach-sum +! ;

0 foreach-sum !
cons-list ' foreach-add ulist-for-each
T{ foreach-sum @                    -> 1000 }T   \ 100+200+300+400

0 foreach-sum !
ulist-null ' foreach-add ulist-for-each
T{ foreach-sum @                    -> 0 }T

\ ===============================================================
\ ulist-reverse (non-destructive: оригинал не трогается)
\ ===============================================================
cons-list ulist-reverse value rev-list

T{ rev-list ulist-len               -> 4 }T
T{ rev-list 0 ulist-nth-addr        -> obj-d }T
T{ rev-list 1 ulist-nth-addr        -> obj-c }T
T{ rev-list 2 ulist-nth-addr        -> obj-b }T
T{ rev-list 3 ulist-nth-addr        -> obj-a }T

\ оригинал не изменён
T{ cons-list 0 ulist-nth-addr       -> obj-a }T
T{ cons-list 3 ulist-nth-addr       -> obj-d }T

T{ ulist-null ulist-reverse         -> 0 }T

\ узлы rev — новые, не те же, что cons-list
T{ rev-list cons-list <>            -> true }T

\ ===============================================================
\ ulist-copy (shallow): новые узлы, addr те же
\ ===============================================================
cons-list ulist-copy value copy-list

T{ copy-list ulist-len              -> 4 }T
T{ copy-list 0 ulist-nth-addr       -> obj-a }T
T{ copy-list 3 ulist-nth-addr       -> obj-d }T
T{ copy-list cons-list <>           -> true }T
T{ ulist-null ulist-copy            -> 0 }T

\ ===============================================================
\ ulist-map: ( addr -- addr' )
\ ===============================================================
: map-to-x ( addr -- addr ) drop obj-x ;
: map-id   ( addr -- addr ) ;

cons-list ' map-to-x ulist-map value mx-list
T{ mx-list ulist-len                -> 4 }T
T{ mx-list 0 ulist-nth-addr         -> obj-x }T
T{ mx-list 1 ulist-nth-addr         -> obj-x }T
T{ mx-list 2 ulist-nth-addr         -> obj-x }T
T{ mx-list 3 ulist-nth-addr         -> obj-x }T

cons-list ' map-id ulist-map value mi-list
T{ mi-list ulist-len                -> 4 }T
T{ mi-list 0 ulist-nth-addr         -> obj-a }T
T{ mi-list 3 ulist-nth-addr         -> obj-d }T
T{ mi-list cons-list <>             -> true }T

T{ ulist-null ' map-id ulist-map    -> 0 }T

\ ===============================================================
\ ulist-append! (destructive по list1)
\ ===============================================================
\ Готовим свежие копии, чтобы не портить cons-list для следующих тестов.
cons-list ulist-copy value app-l1   \ [a b c d]
obj-x ulist-null ulist-cons value app-l2   \ [x]

app-l1 app-l2 ulist-append! value app-res
T{ app-res ulist-len                -> 5 }T
T{ app-res 0 ulist-nth-addr         -> obj-a }T
T{ app-res 4 ulist-nth-addr         -> obj-x }T

\ append: пустой + список → список
T{ 0 cons-list ulist-append! cons-list = -> true }T

\ append: список + пустой → список
T{ cons-list 0 ulist-append! cons-list = -> true }T

\ append: пустой + пустой → пустой
T{ 0 0 ulist-append!                -> 0 }T

\ ===============================================================
\ ulist-free: после освобождения новой цепочки allocate продолжает работать
\ ===============================================================
obj-a ulist-null ulist-cons value tmp-list
obj-b tmp-list   ulist-cons to tmp-list
tmp-list ulist-free
\ просто проверка, что после free мы можем создавать новые узлы
obj-c ulist-null ulist-cons value after-free
T{ after-free ulist-len             -> 1 }T
T{ after-free ulist-addr@           -> obj-c }T

\ ===============================================================
\ enum-диспетчер ulist-do
\ ===============================================================
T{ cons-list uop-empty? ulist-do    -> false }T
T{ ulist-null uop-empty? ulist-do   -> true  }T
T{ cons-list uop-addr@ ulist-do     -> obj-a }T
T{ ulist-null uop-addr@ ulist-do    -> 0     }T
T{ cons-list uop-next@ ulist-do ulist-addr@ -> obj-b }T
T{ ulist-null uop-next@ ulist-do    -> 0     }T
T{ cons-list uop-len    ulist-do    -> 4 }T
T{ ulist-null uop-len   ulist-do    -> 0 }T

\ uop-reverse возвращает новый список — проверим длину и голову
cons-list uop-reverse ulist-do value do-rev
T{ do-rev ulist-len                 -> 4 }T
T{ do-rev 0 ulist-nth-addr          -> obj-d }T

cons-list uop-copy ulist-do value do-copy
T{ do-copy ulist-len                -> 4 }T
T{ do-copy 0 ulist-nth-addr         -> obj-a }T
T{ do-copy cons-list <>             -> true }T
