# fenum

Forth-библиотека: **ulist** (universal list) — односвязный список узлов с полями `next` и `addr`, плюс enum-стиль операций.

Префикс **u** в `ulist` / `uop-*` — от **universal**: узел не хранит данные объекта, а только его адрес, поэтому в одной цепочке могут быть объекты любого типа (структура, массив, `variable` и т.д.).

Имя пакета **fenum** = **f**orth + **enum** (диспетчер `uop-*`).

Создано с [FMix](https://github.com/VitaSound/fmix).

## Зависимости

```bash
fmix packages.get
```

## Подключение

```forth
require ./fenum.4th
\ или по частям:
require ./fenum-ulist.4th
require ./fenum-enum.4th
```

## ulist — universal list

| | Обычный l-list | `ulist` |
|---|----------------|---------|
| В узле | часто само значение | `ulist-addr` — указатель на объект |
| Тип элементов | обычно один | любой, по адресу |

```
struct
    cell% field ulist-next
    cell% field ulist-addr
constant ulist-node%
```

## Модули

Все файлы пакета имеют единый префикс `fenum-`, точка входа — `fenum.4th`.

| Файл | Назначение |
|------|------------|
| `fenum.4th` | точка входа (require обоих модулей) |
| `fenum-ulist.4th` | структура узла, конструктор, обход, поиск, copy/reverse/map/append |
| `fenum-enum.4th` | enum-операции: константы `uop-*`, обёртки `uop-*-exec`, диспетчер `ulist-do` |
| `tests/fenum-ulist_test.4th` | тесты на ttester |

## Слова `ulist`

| Слово | Стек | Описание |
|---|---|---|
| `ulist-null` | `-- 0` | пустой список |
| `ulist-node` | `addr next -- node` | создать узел (allocate) |
| `ulist-cons` | `addr list -- list` | добавить в голову |
| `ulist-empty?` | `list -- flag` | список пуст? |
| `ulist-addr@` | `node -- addr` | адрес объекта |
| `ulist-next@` | `node -- list` | хвост |
| `ulist-addr!` | `node addr --` | заменить адрес |
| `ulist-next!` | `node next --` | заменить хвост |
| `ulist-len` | `list -- n` | длина |
| `ulist-for-each` | `list xt --` | xt: `( addr -- )` |
| `ulist-find-addr` | `list addr -- node\|0` | поиск узла по addr |
| `ulist-contains?` | `list addr -- flag` | есть ли addr |
| `ulist-nth` | `list n -- node\|0` | n-й узел (0-based) |
| `ulist-nth-addr` | `list n -- addr\|0` | n-й addr |
| `ulist-reverse` | `list -- list'` | новая обратная цепочка |
| `ulist-copy` | `list -- list'` | поверхностная копия |
| `ulist-map` | `list xt -- list'` | xt: `( addr -- addr' )` |
| `ulist-append!` | `list1 list2 -- list` | **destructive**: list2 в хвост list1 |
| `ulist-free` | `list --` | освободить узлы (объекты не трогает) |

## Enum-операции

Константы (`uop-*`) — унарные операции для `ulist-do`:

```forth
0 constant uop-empty?
1 constant uop-addr@
2 constant uop-next@
3 constant uop-len
4 constant uop-reverse
5 constant uop-copy
```

```forth
head uop-len     ulist-do .   \ длина
head uop-addr@   ulist-do .   \ адрес объекта в голове
head uop-reverse ulist-do .   \ новый обратный список
```

Бинарные/xt-операции (`ulist-for-each`, `ulist-map`, `ulist-find-addr`, `ulist-cons`, `ulist-append!`) через `ulist-do` не идут — вызывайте их напрямую.

## Пример

```forth
require ./fenum.4th

variable item-a  100 item-a !
variable item-b  200 item-b !
variable item-c  300 item-c !

\ Собираем список: a -> b -> c -> 0
item-c ulist-null ulist-cons
item-b swap       ulist-cons
item-a swap       ulist-cons value head

head ulist-len .                       \ 3
head 1 ulist-nth-addr item-b = .       \ -1
head item-b ulist-contains? .          \ -1

: print-addr ( addr -- ) @ . ;
head ' print-addr ulist-for-each       \ 100 200 300

head ulist-reverse value rev           \ новая цепочка c -> b -> a

head ulist-free
rev  ulist-free
```

## Тесты

```bash
fmix test
```
