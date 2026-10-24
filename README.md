# fenum

[![Cov](https://img.shields.io/badge/Cov-98%25-brightgreen.svg)](https://github.com/VitaSound/fenum)
[![Version](https://img.shields.io/badge/version-0.1.3-blue.svg)](CHANGELOG.md)

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

**struct.fs backend** (по умолчанию):

```forth
require ./fenum.4th
```

**begin-structure backend** (fhdlgen, проекты на `field:`):

```forth
require ./fenum-bs.4th
```

В **одном образе Gforth** нельзя смешивать `require ./fenum.4th` и `require ./fenum-bs.4th`, а также нельзя загружать `fenum.4th` рядом с `begin-structure` — `struct.fs` ломает `field:`.

| Backend | Точка входа | Struct |
|---------|-------------|--------|
| struct.fs | `fenum.4th` | `struct` / `cell% field` |
| begin-structure | `fenum-bs.4th` | `begin-structure` / `field:` |

Публичный API (`ulist-*`, `enum-*`, `TYPE_*`) **одинаковый**.

## Модули

| Файл | Назначение |
|------|------------|
| `fenum.4th` | точка входа (struct.fs) |
| `fenum-bs.4th` | точка входа (begin-structure) |
| `fenum-types.4th` | константы `TYPE_*` (`TYPE_ULIST`, `TYPE_HASHMAP`, `TYPE_ADDR`) |
| `fenum-container.4th` | `container%` (struct.fs) |
| `fenum-term.4th` | общий терм-слой: `[type v1 v2]`, `TM-*`, `term!`/`term=`/`term-cmp` |
| `fenum-addrlist.4th` | адресный список-примитив `addrlist-*` (бывший ulist) |
| `fenum-ulist.4th` | термовый список `ulist-*`: элемент — терм, общие `t-*`/`term*` |
| `fenum-hashmap.4th` | хеш-мапа `hashmap-*`: ключ и значение — термы |
| `fenum-ulist-bs.4th` | адресный `ulist-*` (begin-structure) |
| `fenum-enum-core.4th` | `enum-each`, `enum-sort` (общий код) |
| `fenum-enum.4th` | struct.fs + enum-core |
| `tests/fenum-term_test.4th` | тесты терм-слоя |
| `tests/fenum-ulist_test.4th` | тесты термового ulist (struct.fs) |
| `tests/fenum-addrlist_test.4th` | тесты адресного addrlist (struct.fs) |
| `tests/fenum-hmap_test.4th` | тесты hashmap |
| `tests/fenum_bs_test.4th` | прогон bs backend через `scripts/run-bs-tests.sh` |
| `tests/bs/fenum-ulist-bs_test.4th` | ulist + interop begin-structure (отдельный Gforth) |
| `tests/bs/fenum-enum-bs_test.4th` | enum-* (отдельный Gforth) |
| `tests/fenum-enum_test.4th` | тесты enum-* (struct.fs) |

## Стек-конвенция

Контейнер всегда **на топе стека** (последний аргумент перед словом):

```forth
vt v1 v2  lst   ulist-add           \ термовый список
vt v1 v2  lst   ulist-contains-term?
n         lst   ulist-nth-term
xt        lst   ulist-each          \ xt: ( term-addr )

addr      lst   addrlist-add        \ адресный примитив
addr      lst   addrlist-contains?
n         lst   addrlist-nth-addr

xt        c     enum-each
0 | xt    c     enum-sort           \ xt = адрес слова cmp, 0 = дефолт
```

Это аналог Forth-идиомы `value addr !`, где «получатель» — на верхушке.

## API: `ulist` (термовый список)

Элемент — **терм** `[type v1 v2]` общего слоя `fenum-term` (в духе
Elixir: любой тип, поле-тег `TM-*` — внутренняя деталь). Узел хранит
терм на смещении 0, поэтому работают общие слова `t-type`/`t-v1`/`t-v2`.

| Слово | Стек | Описание |
|---|---|---|
| `ulist-new` | `( -- lst )` | создать пустой список |
| `ulist-empty?` | `( lst -- flag )` | пустой? |
| `ulist-len` | `( lst -- n )` | длина |
| `ulist-add` | `( vt v1 v2 lst -- )` | добавить терм в голову (O(1), prepend) |
| `ulist-contains-term?` | `( vt v1 v2 lst -- flag )` | содержит терм? (`term=`, строки — по содержимому) |
| `ulist-nth-term` | `( n lst -- vt v1 v2 )` | n-й терм, 0-based, вне диапазона → `0 0 0` |
| `ulist-each` | `( xt lst -- )` | xt: `( term-addr -- )` для каждого элемента |
| `ulist-reverse` | `( lst -- )` | in-place разворот |
| `ulist-clear` | `( lst -- )` | удалить узлы; `lst` остаётся валидным пустым |
| `ulist-dispose` | `( lst -- )` | освободить узлы + сам заголовок (после этого `lst` использовать нельзя) |

Сами узлы списка — внутренние, наружу не торчат. Заголовок `ulist` стабилен: операции вроде `ulist-add` или `ulist-reverse` не меняют адрес `lst`.

Строки (`TM-STR`) хранятся без копии (`ptr,len` указывают на владельца)
— как и раньше в адресном списке.

## API: `addrlist` (адресный примитив)

Низкоуровневый список адресов (бывший `ulist`): элемент — голая
ячейка-адрес, тип живёт снаружи. Потребители с адресной семантикой
(например, параметры flua) работают с ним напрямую.

| Слово | Стек | Описание |
|---|---|---|
| `addrlist-new` | `( -- lst )` | создать (obj-type = `TYPE_ADDR`) |
| `addrlist-add` | `( addr lst -- )` | добавить адрес в голову |
| `addrlist-contains?` | `( addr lst -- flag )` | содержит адрес? |
| `addrlist-nth-addr` | `( n lst -- addr\|0 )` | n-й адрес, вне диапазона → 0 |
| `addrlist-len` / `addrlist-empty?` | `( lst -- n/flag )` | длина / пустой? |
| `addrlist-each` | `( xt lst -- )` | xt: `( addr -- )` |
| `addrlist-dispose` | `( lst -- )` | освободить |

`obj-type = TYPE_ADDR` отличает его от термового `ulist` (`TYPE_ULIST`)
в диспетчере `enum-*`.

## API: `enum-*`

| Слово | Стек | Описание |
|---|---|---|
| `enum-each` | `( xt c -- )` | обойти контейнер; xt получает элемент в форме своего типа |
| `enum-sort` | `( cmp c -- new )` | `cmp` — **адрес слова сравнения** (`' имя`, функция высшего порядка) или `0` — дефолтное сравнение; возвращает новый упорядоченный контейнер |

### Контракт cmp (HOF)

`cmp: ( el-a el-b -- flag )` — `flag ≠ 0` означает «порядок не менять»,
`el-a` не позже `el-b` (отношение ≤, как `Enum.sort/2` в Elixir).
Что получает cmp как `el-*`:

| Тип контейнера | el — это | дефолт при `cmp = 0` | результат `enum-sort` |
|---|---|---|---|
| `TYPE_ADDR` | адрес ячейки-элемента (addrlist) | содержимое ячейки численно | новый `addrlist` |
| `TYPE_ULIST` | терм-адрес элемента | `term-cmp` (сначала тег типа, затем содержимое) | новый `ulist` (копии термов) |
| `TYPE_HASHMAP` | slot (ключ-терм на смещении 0, значение = `+3 cells`) | `term-cmp` по ключам | новый `ulist` ПАР `TM-PAIR` |

Сортировка мапа — **по ключам** (семантика Elixir `Enum.sort(map)`),
значения выстраиваются в порядке возрастания ключей. `TYPE_ADDR`
отделяет адресный примитив от термового списка — у них разная
модель элемента, хотя оба исторически назывались `ulist`.

```forth
0 xs enum-sort                 \ дефолт: cmp = 0
' my-cmp xs enum-sort          \ своё слово: ( el-a el-b -- flag )
' my-cmp h enum-sort           \ по ключам мапа, cmp видит ключ-термы
```

Добавление нового типа контейнера = константа `TYPE_*`, слова
`xxx-each`, `of`-ветки в `enum-each` / `enum-sort`, подключить `xxx`
в `fenum.4th`.

Результат `enum-sort` для мапа — список пар `TM-PAIR`, где `v1`/`v2` —
адреса ключевого и значимого термов **в пуле исходной мапы**: результат
читать, пока жива исходная мапа.

## Пример

```forth
require ./fenum.4th

\ термовый список: элементы — термы TM-INT
ulist-new value xs
TM-INT 1 0 xs ulist-add  TM-INT 2 0 xs ulist-add  TM-INT 3 0 xs ulist-add
TM-INT 4 0 xs ulist-add  TM-INT 5 0 xs ulist-add
\ xs (head → tail): 5, 4, 3, 2, 1

\ обойти и напечатать (для TM-INT значение лежит в v1)
: .t ( term-addr -- )  t-v1 @ @ . ;
' .t xs ulist-each       \ 5 4 3 2 1
' .t xs enum-each        \ то же через диспетчер

\ отсортировать по возрастанию: cmp = 0 → term-cmp
0 xs enum-sort value sorted
' .t sorted ulist-each   \ 1 2 3 4 5

\ своё слово сравнения (HOF): убывание
: desc ( a b -- f )  swap t-v1 @ @ swap t-v1 @ @ >= ;
' desc xs enum-sort value top
' .t top ulist-each      \ 5 4 3 2 1

\ in-place разворот: xs (head → tail) теперь 1, 2, 3, 4, 5
xs ulist-reverse
' .t xs ulist-each       \ 1 2 3 4 5

top ulist-dispose  sorted ulist-dispose  xs ulist-dispose
```

Адресный примитив — та же картина, но элемент = адрес ячейки:

```forth
addrlist-new value ys
v1 ys addrlist-add  v2 ys addrlist-add  v3 ys addrlist-add
: .v ( addr -- )  @ . ;
: asc ( a b -- f )  swap @ swap @ <= ;
' asc ys enum-sort value vsorted
' .v vsorted addrlist-each   \ 1 2 3
```

## Полиморфизм

`enum-each` / `enum-sort` работают с любым контейнером, реализующим
свой `*-each`; выбор — по `obj-type`:

```forth
hashmap-new value h
TM-STR s" b" TM-INT 20 0 h hashmap-set
TM-STR s" a" TM-INT 10 0 h hashmap-set

\ обход: xt получает slot (ключ-терм на смещении 0)
' .slot h enum-each

\ сортировка ПО КЛЮЧАМ (cmp = 0 → term-cmp по ключам):
\ результат — ulist пар TM-PAIR в порядке возрастания ключей
0 h enum-sort value kv
```

## Подводные камни

- **Два backend'а, один образ.** Выберите `fenum.4th` **или** `fenum-bs.4th`, не оба. `struct.fs` и `begin-structure` в одной сессии Gforth несовместимы.
- **`'` vs `[']`.** Внутри определений (`:`) передавайте xt через `[']`, на верхнем уровне — `'`. Это правило Forth, не специфика fenum.
- **`enum-sort` не реентерабельна.** Внутри использует глобальные `variable` (массив, длина, индекс, cmp-xt). Нельзя вызвать `enum-sort` из xt другого `enum-sort`. Для обычного использования это не проблема.
- **`enum-sort` всегда выделяет новый контейнер.** Не забывайте его освободить (`ulist-dispose` / `addrlist-dispose`).
- **Результат сортировки мапа ссылается в её пул.** Пары `TM-PAIR` хранят адреса термов ключа/значения в слотах исходной мапы: не `hashmap-dispose` мапу раньше, чем прочитан результат.
- **`r@` внутри `?do` не использовать:** loop держит return stack — собранный контейнер в `%sort-to-*` живёт в переменной, а не в `>r`.
- **В интерпретаторе имя исполняется, xt даёт `'`** (в колонке — наоборот: `[']`). `0 sort-hm` работает, `cmp sort-hm` без `'` уйдёт в исполнение cmp.
- **После `ulist-dispose` списком пользоваться нельзя.** Если нужен повторный цикл — `ulist-clear`, не `-dispose`.
- **`ulist-add` кладёт в голову.** Порядок head→tail обратный порядку добавления. `enum-sort` об этом знает и собирает результат корректно.

## Тесты

```bash
fmix test    # struct.fs + begin-structure (bs — в отдельных процессах Gforth)
flint
fcov run fmix test && fcov report
```

`fmix test` подхватывает `tests/fenum_bs_test.4th`: он запускает `scripts/run-bs-tests.sh`, который гоняет `tests/bs/*` в **чистом** Gforth. Так оба backend'а проверяются одной командой.

Вручную только bs:

```bash
./scripts/run-bs-tests.sh
```

## Экосистема VitaSound

- [feco](https://github.com/VitaSound/feco) — каталог Forth-тулчейна: версии, покрытие, установка всех репозиториев
- [MIT](https://github.com/VitaSound/MIT) — инженерная методология: декомпозиция задач и уровни аппаратно-программного стека
