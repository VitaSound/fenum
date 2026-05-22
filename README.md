# fenum

Forth-библиотека универсальных контейнеров на чистых `struct` с type-tag-диспетчером в стиле Elixir `Enum`.

## Идея

В Elixir данные отделены от функций: `Enum.each(list, fn)`, `Enum.sort(list, fn)` работают с любым перечислимым типом. У самого `List` нет «методов» — это просто структура данных, а универсальные операции живут в модуле `Enum`.

`fenum` повторяет тот же подход для Gforth:

- Каждый контейнер — обычная `struct`, начинающаяся с поля `obj-type` (типовая метка).
- Слова контейнера (`ulist-*`) — обычные процедуры, без ООП-диспатча.
- Слова `enum-*` смотрят на `obj-type` и направляют вызов соответствующему контейнеру через `case`.
- Добавить новый тип контейнера = добавить константу `TYPE_*`, реализовать его слова и дописать `of`-ветку в `enum-*`.

Никаких классов, методов, vtable. Только структуры и слова.

Создано с [FMix](https://github.com/VitaSound/fmix).

## Зависимости

```bash
fmix packages.get
```

Используются стандартные модули Gforth: `struct.fs`.

## Подключение

```forth
require ./fenum.4th
```

## Модули

| Файл | Назначение |
|------|------------|
| `fenum.4th` | точка входа |
| `fenum-container.4th` | `container%` (`obj-type`) + константы типов `TYPE_*` |
| `fenum-ulist.4th` | universal односвязный список (`ulist-*`) |
| `fenum-enum.4th` | диспетчеры `enum-each`, `enum-sort` |
| `tests/fenum-ulist_test.4th` | тесты `ulist` |
| `tests/fenum-enum_test.4th` | тесты `enum-*` |

## Стек-конвенция

Контейнер всегда **на топе стека** (последний аргумент перед словом):

```forth
addr  lst   ulist-add
addr  lst   ulist-contains?
n     lst   ulist-nth-addr
xt    lst   ulist-each
xt    lst   enum-each
xt    lst   enum-sort
```

Это аналог Forth-идиомы `value addr !`, где «получатель» — на верхушке.

## API: `ulist`

| Слово | Стек | Описание |
|---|---|---|
| `ulist-new` | `( -- lst )` | создать пустой список |
| `ulist-empty?` | `( lst -- flag )` | пустой? |
| `ulist-len` | `( lst -- n )` | длина |
| `ulist-add` | `( addr lst -- )` | добавить в голову (O(1)) |
| `ulist-contains?` | `( addr lst -- flag )` | содержит адрес? |
| `ulist-nth-addr` | `( n lst -- addr\|0 )` | n-й адрес, 0-based, вне диапазона → 0 |
| `ulist-each` | `( xt lst -- )` | xt: `( addr -- )` для каждого элемента |
| `ulist-reverse` | `( lst -- )` | in-place разворот |
| `ulist-clear` | `( lst -- )` | удалить узлы; `lst` остаётся валидным пустым |
| `ulist-dispose` | `( lst -- )` | освободить узлы + сам заголовок (после этого `lst` использовать нельзя) |

Сами узлы списка — внутренние, наружу не торчат. Заголовок `ulist` стабилен: операции вроде `ulist-add` или `ulist-reverse` не меняют адрес `lst`.

## API: `enum-*`

| Слово | Стек | xt | Описание |
|---|---|---|---|
| `enum-each` | `( xt c -- )` | `( addr -- )` | обойти контейнер |
| `enum-sort` | `( xt c -- new-ulist )` | `( a b -- flag )` | вернуть новый отсортированный `ulist`; `flag=true` означает «`a` должен идти перед `b`» |

`enum-sort` всегда возвращает `ulist` — как `Enum.sort` в Elixir всегда возвращает `List`.

Список покрытых типов на сегодня: `TYPE_ULIST`. Добавление новых типов (`TYPE_HASHMAP` и т.д.) — это новая `of`-ветка в `enum-each` / `enum-sort` плюс реализация соответствующих `xxx-each` / `xxx-sort`.

## Пример

```forth
require ./fenum.4th

variable v1   1 v1 !
variable v2   2 v2 !
variable v3   3 v3 !
variable v4   4 v4 !
variable v5   5 v5 !

ulist-new value xs
v1 xs ulist-add  v2 xs ulist-add  v3 xs ulist-add
v4 xs ulist-add  v5 xs ulist-add
\ xs (head → tail): 5, 4, 3, 2, 1

\ обойти и напечатать
: .v ( addr -- )  @ . ;
' .v xs ulist-each       \ 5 4 3 2 1
' .v xs enum-each        \ то же через диспетчер

\ отсортировать по возрастанию (cmp: *a <= *b)
: asc ( a b -- f )  swap @ swap @ <= ;

' asc xs enum-sort value sorted
' .v sorted ulist-each   \ 1 2 3 4 5

\ in-place разворот: xs (head → tail) теперь 1, 2, 3, 4, 5
xs ulist-reverse
' .v xs ulist-each       \ 1 2 3 4 5

sorted ulist-dispose
xs ulist-dispose
```

## Полиморфизм

`enum-each` / `enum-sort` работают с любым контейнером, реализующим свой `*-each` (для сортировки используется `ulist` как промежуточный буфер):

```forth
\ когда появится hashmap, тот же код продолжит работать:
hashmap-new value h
\ ...
' .v h enum-each
' asc h enum-sort value top   \ → ulist значений в порядке cmp
```

## Подводные камни

- **`'` vs `[']`.** Внутри определений (`:`) передавайте xt через `[']`, на верхнем уровне — `'`. Это правило Forth, не специфика fenum.
- **`enum-sort` не реентерабельна.** Внутри использует глобальные `variable` (массив, длина, индекс, cmp-xt). Нельзя вызвать `enum-sort` из xt другого `enum-sort`. Для обычного использования это не проблема.
- **`enum-sort` всегда выделяет новый `ulist`.** Не забывайте `ulist-dispose` результата.
- **После `ulist-dispose` списком пользоваться нельзя.** Если нужен повторный цикл — `ulist-clear`, не `-dispose`.
- **`ulist-add` кладёт в голову.** Порядок head→tail обратный порядку добавления. `enum-sort` об этом знает и собирает результат корректно.

## Тесты

```bash
fmix test
```
