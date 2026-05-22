# fenum

Forth-библиотека универсальных контейнеров на ООП (`mini-oof2`) с набором функций высшего порядка в стиле Elixir `Enum`.

Идея простая: базовый класс `container` задаёт интерфейс (`add`, `each`, `len`, `contains?`, `nth-addr`, `clear`, `reverse`, `dispose`, `new-empty`). Конкретные контейнеры наследуют его и переопределяют методы. Поверх интерфейса лежат полиморфные слова `enum-filter`, `enum-map`, `enum-reduce`, `enum-count`, `enum-find`, `enum-any?`, `enum-all?` — они работают с **любым** наследником `container` без изменений.

Сейчас реализован `ulist` (universal односвязный список). При добавлении `hashmap` или другого контейнера все `enum-*` сразу с ним заработают.

Создано с [FMix](https://github.com/VitaSound/fmix).

## Зависимости

```bash
fmix packages.get
```

Используются стандартные модули Gforth: `mini-oof2.fs`, `stuff.fs`.

## Подключение

```forth
require ./fenum.4th
```

## Модули

| Файл | Назначение |
|------|------------|
| `fenum.4th` | точка входа |
| `fenum-container.4th` | абстрактный класс `container` |
| `fenum-ulist.4th` | класс `ulist` : `container` |
| `fenum-enum.4th` | HOF: `enum-filter` `-map` `-reduce` `-count` `-find` `-any?` `-all?` |
| `tests/fenum-ulist_test.4th` | тесты ulist |
| `tests/fenum-enum_test.4th` | тесты HOF |

## Интерфейс `container`

| Метод | Стек | Описание |
|---|---|---|
| `empty?` | `( -- flag )` | пустой? |
| `len` | `( -- n )` | количество элементов |
| `add` | `( addr -- )` | добавить объект (в `ulist` — в голову, O(1)) |
| `contains?` | `( addr -- flag )` | содержит объект? |
| `nth-addr` | `( n -- addr\|0 )` | n-й объект (0-based) |
| `each` | `( xt -- )` | xt: `( addr -- )` для каждого элемента |
| `clear` | `( -- )` | удалить все элементы |
| `reverse` | `( -- )` | для упорядоченных — in-place; иначе noop |
| `new-empty` | `( -- new-container )` | новый пустой объект **того же класса** |
| `dispose` | `( -- )` | освободить содержимое + сам объект |

Полиморфизм через `new-empty` использует layout `mini-oof2`: класс берётся прямо из объекта (`o cell- @`), поэтому базовая реализация работает для любого наследника без override.

## Семантика вызова метода

`mini-oof2` использует префикс `.`: `arg... obj .method`. **Объект всегда на топе стека**, аргументы — под ним.

```forth
ulist new value lst
obj-a lst .add           \ ( addr obj -- )
0    lst .nth-addr       \ ( n obj -- addr )
obj-a lst .contains?     \ ( addr obj -- flag )
' xt  lst .each          \ ( xt obj -- )
lst .reverse
lst .dispose
```

Альтернатива — блок `>o ... o>` без точки:

```forth
lst >o
    obj-a add
    obj-b add
    len .
o>
```

## HOF в стиле Elixir Enum

Все принимают `container` на топе (после аргументов) и возвращают значение или новый контейнер.

| Слово | Стек | xt | Описание |
|---|---|---|---|
| `enum-count` | `( c xt -- n )` | `( addr -- flag )` | сколько элементов проходят предикат |
| `enum-any?` | `( c xt -- flag )` | `( addr -- flag )` | хотя бы один true |
| `enum-all?` | `( c xt -- flag )` | `( addr -- flag )` | все true (пустой → true) |
| `enum-find` | `( c xt -- addr\|0 )` | `( addr -- flag )` | первый по порядку, для которого xt → true |
| `enum-reduce` | `( c acc xt -- acc' )` | `( addr acc -- acc' )` | свёртка |
| `enum-filter` | `( c xt -- c' )` | `( addr -- flag )` | новый контейнер того же типа |
| `enum-map` | `( c xt -- c' )` | `( addr -- addr' )` | новый контейнер той же длины |

**Важно:** внутри ваших слов `:` передавайте xt через `[']` (не через `'`):

```forth
: positive-only ( c -- c' ) ['] pos? enum-filter ;
```

На верхнем уровне `'` тоже работает.

## Пример

```forth
require ./fenum.4th

variable v1   1 v1 !
variable v2   2 v2 !
variable v3   3 v3 !
variable v4   4 v4 !
variable v5   5 v5 !

ulist new value xs
v1 xs .add  v2 xs .add  v3 xs .add  v4 xs .add  v5 xs .add
\ xs (head → tail): 5, 4, 3, 2, 1

: even? ( a -- f )    @ 1 and 0= ;
: sum-step ( a acc -- acc' ) swap @ + ;

xs ' even?      enum-count  .            \ 2
xs ' even?      enum-any?   .            \ -1 (true)
xs 0 ' sum-step enum-reduce .            \ 15

xs ' even? enum-filter value evens
evens .len .                              \ 2
0 evens .nth-addr v4 = .                  \ -1 (порядок сохранён)
evens .dispose

xs .reverse                               \ теперь 1, 2, 3, 4, 5
xs .dispose
```

## Полиморфизм

Любая функция, работающая через интерфейс `container`, переиспользуется для любого наследника:

```forth
: positive-only ( c -- c' ) ['] pos? enum-filter ;

ulist new value mylist
\ когда появится hashmap:
\ hashmap new value myhash

mylist positive-only ...
\ myhash  positive-only ...           \ тот же код
```

## Подводные камни

- **`'` vs `[']`.** Внутри `:` xt передаётся через `[']`. Снаружи (на верхнем уровне) — `'`. Это правило Forth, не специфика fenum, но `enum-*` особенно чувствительны.
- **`fenum-enum.4th` не реентерабельный.** Внутри использует глобальные `variable` для передачи xt/аккумулятора. Нельзя сделать `enum-filter` внутри callback другого `enum-filter`. Для обычного использования это не проблема.
- **Порядок после filter/map.** Поскольку `.add` в `ulist` кладёт в голову, `enum-filter`/`enum-map` после накопления вызывают `.reverse` — порядок совпадает с порядком итерации входа. Для контейнеров без порядка `reverse` = noop, всё корректно.
- **После `.dispose` объект использовать нельзя.** Используйте `.clear`, если объект ещё пригодится.

## Тесты

```bash
fmix test
```
