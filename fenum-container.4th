\ fenum-container.4th — общая struct-база для всех контейнеров
\
\ Каждый контейнер начинается с поля obj-type. Это позволяет enum-*
\ диспатчить операции по типу без ООП.
\
\ Backend struct.fs (по умолчанию). Для begin-structure см. fenum-bs.4th.

require ./fenum-types.4th
require struct.fs

[IFDEF] container% [ELSE]
struct
    cell% field obj-type
constant container%
1 constant fenum-backend-struct
[THEN]

\ ---------- идентификаторы типов контейнеров ----------
\ см. fenum-types.4th
