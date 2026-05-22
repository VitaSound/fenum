require ../forth-packages/ttester/1.1.0/ttester.4th
require ../fenum.4th

\ ---------------------------------------------------------------
\ Тестовые «объекты» — обычные variable, в list попадают их адреса
\ ---------------------------------------------------------------
variable obj-a   100 obj-a !
variable obj-b   200 obj-b !
variable obj-c   300 obj-c !
variable obj-d   400 obj-d !
variable obj-x   999 obj-x !

\ ---------------------------------------------------------------
\ ulist new — пустой список
\ ---------------------------------------------------------------
ulist new value L0
T{ L0 .empty?                  -> true  }T
T{ L0 .len                     -> 0     }T

\ ===============================================================
\ .add (всегда в голову)
\ ===============================================================
ulist new value lst
T{ obj-a lst .add  lst .len    -> 1     }T
T{ lst .empty?                 -> false }T
T{ 0 lst .nth-addr             -> obj-a }T

T{ obj-b lst .add  lst .len    -> 2     }T
T{ 0 lst .nth-addr             -> obj-b }T   \ свежий — в голове
T{ 1 lst .nth-addr             -> obj-a }T

T{ obj-c lst .add
   obj-d lst .add
   lst .len                    -> 4     }T
T{ 0 lst .nth-addr             -> obj-d }T
T{ 3 lst .nth-addr             -> obj-a }T

\ ===============================================================
\ .nth-addr — границы
\ ===============================================================
T{ 4  lst .nth-addr            -> 0     }T
T{ -1 lst .nth-addr            -> 0     }T
T{ 5  L0  .nth-addr            -> 0     }T

\ ===============================================================
\ .contains?
\ ===============================================================
T{ obj-a lst .contains?        -> true  }T
T{ obj-b lst .contains?        -> true  }T
T{ obj-c lst .contains?        -> true  }T
T{ obj-d lst .contains?        -> true  }T
T{ obj-x lst .contains?        -> false }T
T{ obj-a L0  .contains?        -> false }T

\ ===============================================================
\ .each — сайд-эффект через переменную
\ ===============================================================
variable sum-each   0 sum-each !
: each-add ( addr -- ) @ sum-each +! ;

T{ 0 sum-each !
   ' each-add lst .each
   sum-each @                  -> 1000  }T   \ 100+200+300+400

T{ 0 sum-each !
   ' each-add L0 .each
   sum-each @                  -> 0     }T   \ пустой — xt не вызывается

\ Порядок обхода: от головы (последний .add) к хвосту (первый .add)
variable order-buf
create order-cells 16 cells allot
0 order-buf !

: order-record ( addr -- )
    order-buf @ cells order-cells +
    !                       \ записать addr
    1 order-buf +! ;

ulist new value L-ord
obj-a L-ord .add   \ хвост
obj-b L-ord .add
obj-c L-ord .add   \ голова

0 order-buf !
' order-record L-ord .each
T{ order-buf @                 -> 3      }T
T{ 0 cells order-cells + @     -> obj-c  }T
T{ 1 cells order-cells + @     -> obj-b  }T
T{ 2 cells order-cells + @     -> obj-a  }T

\ ===============================================================
\ .clear + повторное использование
\ ===============================================================
T{ lst .clear   lst .empty?    -> true   }T
T{ lst .len                    -> 0      }T
T{ obj-x lst .contains?        -> false  }T
T{ obj-a lst .add   lst .len   -> 1      }T
T{ 0 lst .nth-addr             -> obj-a  }T

\ .clear на пустом — no-op
T{ L0 .clear   L0 .empty?      -> true   }T

\ ===============================================================
\ Полиморфизм: тот же код для любого container-наследника
\ ===============================================================
\ Сейчас наследник только один (ulist), но проверим, что объект
\ полноценно работает через статически объявленный value-слот.

ulist new value some-container

T{ obj-a some-container .add
   obj-b some-container .add
   some-container .len          -> 2     }T

\ универсальная функция, не знающая конкретного типа
: dump-len ( container -- n ) .len ;
T{ some-container dump-len     -> 2     }T

: any-empty? ( container -- flag ) .empty? ;
T{ L0 any-empty?               -> true  }T
T{ some-container any-empty?   -> false }T

\ ===============================================================
\ .reverse — in-place разворот ulist
\ ===============================================================
ulist new value rev-lst
obj-a rev-lst .add
obj-b rev-lst .add
obj-c rev-lst .add   \ список: c -> b -> a

T{ 0 rev-lst .nth-addr         -> obj-c }T
T{ 2 rev-lst .nth-addr         -> obj-a }T

T{ rev-lst .reverse
   0 rev-lst .nth-addr         -> obj-a }T
T{ 2 rev-lst .nth-addr         -> obj-c }T
T{ rev-lst .len                -> 3     }T

\ дважды — обратно
T{ rev-lst .reverse
   0 rev-lst .nth-addr         -> obj-c }T

\ reverse пустого
ulist new value rev-empty
T{ rev-empty .reverse  rev-empty .empty? -> true }T

\ reverse из одного элемента
ulist new value rev-one
obj-a rev-one .add
T{ rev-one .reverse
   0 rev-one .nth-addr         -> obj-a }T
T{ rev-one .len                -> 1     }T

\ ===============================================================
\ .dispose — освобождение объекта + его узлов
\ ===============================================================
\ После .dispose объект использовать нельзя; проверяем что вызов
\ не падает и не утекает (на сколько может тест ttester).
ulist new value disp-lst
obj-a disp-lst .add
obj-b disp-lst .add
obj-c disp-lst .add
T{ disp-lst .dispose            -> }T

\ повторно создаём после dispose
ulist new value disp-lst2
T{ disp-lst2 .empty?            -> true }T
T{ disp-lst2 .dispose           -> }T

\ dispose на пустом
ulist new value disp-empty
T{ disp-empty .dispose          -> }T
