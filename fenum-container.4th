\ fenum-container.4th — общая struct-база для всех контейнеров
\
\ Каждый контейнер начинается с поля obj-type. Это позволяет enum-*
\ диспатчить операции по типу без ООП.
\
\ Backend struct.fs (по умолчанию). Для begin-structure см. fenum-bs.4th.

require ./fenum-types.4th
require struct.fs

\ end-struct-const: закрыть struct-протокол (align size) обычной
\ константой-размером — одной ячейкой, как ждёт `X allocate`.
\ Штатный end-struct здесь не подходит: он даёт 2constant и тогда
\ `unode% allocate` оставлял бы align на стеке. Без закрытия обе
\ ячейки протокола (align снизу, size сверху) утекали в стек данных
\ при require — отсюда <2> 8 8 после загрузки fenum.
[IFDEF] end-struct-const [ELSE]
: end-struct-const ( align size "name" -- )
    over naligned nip constant ;
[THEN]

[IFDEF] container% [ELSE]
struct
    cell% field obj-type
end-struct container%            \ 2constant ( align size ): пара нужна
                                  \ fenum-ulist.4th как начало расширения
1 constant fenum-backend-struct
[THEN]

\ ---------- идентификаторы типов контейнеров ----------
\ см. fenum-types.4th
