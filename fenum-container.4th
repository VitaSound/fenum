\ fenum-container.4th — общая struct-база для всех контейнеров
\
\ Каждый контейнер начинается с поля obj-type. Это позволяет enum-*
\ диспатчить операции по типу без ООП.

require struct.fs

struct
    cell% field obj-type
constant container%

\ ---------- идентификаторы типов контейнеров ----------
0 constant TYPE_ULIST
1 constant TYPE_HASHMAP        \ заготовка
