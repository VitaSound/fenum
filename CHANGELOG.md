# Change Log

All notable changes to fenum are documented here.

The format is based on [Keep a Changelog](http://keepachangelog.com/) and
this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

### Added
- **Универсальный терм-слой `fenum-term.4th`**: формат `[type v1 v2]` с
  полем-тегом `TM-*` (`TM-INT/STR/MAP/LST/PTR/PAIR`) — единые слова
  `term!`/`term@`/`term=`/`term-s=`/`term-copy!`, конструкторы
  `t-int!`…`t-pair!`. Ключ и значение hashmap, элементы термового
  списка и пары результата сортировки — одним и тем же форматом
  (как в Erlang/Elixir: элементы мапы — любые типы, включая другие
  мапы — `TM-MAP`).
- **`term-cmp ( a b -- flag )`** — порядок термов (тег типа, затем
  содержимое; строки посимвольно через `compare`) для сортировки
  с дефолтным cmp.
- **`fenum-addrlist.4th`** — адресный список-примитив (бывший `ulist`
  без изменений модели: элемент = адрес ячейки). Потребители с
  адресной семантикой (flua) переведены на `addrlist-*`.
- **`TYPE_ADDR`** — адресный примитив и термовый `ulist` разделены
  по типу в диспетчере `enum-*` (у них разная модель элемента).
- Тесты: `fenum-term_test`, `fenum-hmap_test`, `fenum-ulist_test`
  (термовый: типы INT/STR/PTR, вложенность мапа в списке),
  `fenum-addrlist_test`.

### Changed
- **`fenum-ulist.4th` переписан как термовый список** (Elixir-стиль):
  узел `{type v1 v2 next}`, терм на смещении 0 — работают общие
  `t-*`/`term*`; API `ulist-add ( vt v1 v2 lst )`,
  `ulist-nth-term`, `ulist-contains-term?`, `ulist-each (xt: term-addr)`.
- **`enum-sort` — честный HOF**: `cmp` передаётся адресом слова
  (`' имя`) или `0` — дефолтное сравнение (`%cmp-addr-def` /
  `term-cmp`). Контракт cmp: `( el-a el-b -- flag )`, где `el-*` —
  адрес элемента в форме типа контейнера. Поддержаны все три типа:
  `TYPE_ADDR`, `TYPE_ULIST`, `TYPE_HASHMAP`.
- **Сортировка мапа — по ключам** (семантика Elixir `Enum.sort(map)`):
  cmp видит slot (= ключ-терм), результат — `ulist` пар `TM-PAIR`
  (v1/v2 — адреса ключевого/значимого термов в пуле мапы).

### Fixed
- `hashmap-each`: пустой слот не снимал адрес с data stack
  (утечка по адресу на каждый свободный слот: 126 на ёмкости 128).
- `%sort-to-ulist` / `%sort-to-pairs`: `r@` внутри `?do` конфликтовал
  с return stack цикла — собираемый контейнер переведён на переменную.
- `nd-new` (этап 2): порядок записи терма — `next` сдвигал `term!`,
  терм писался по мусорному адресу.
- `ulist-nth-term` вне диапазона: возвращал 4 нуля вместо тройки.
- Семантика `variable` в `%elm`: имя кладёт адрес — требовался `@`.

## [0.1.3] - 2026-10-23

### Fixed
- Data-stack leak on `require`: struct-протокол `( align size )` закрывался
  обычным `constant`, который снимал только `size`, — нижняя `align`
  утекала в data stack (`<2> 8 8` после загрузки `fenum.4th`).
  `container%` теперь закрывается штатным `end-struct` (2constant
  `( align size )` — пара нужна `fenum-ulist.4th` для расширения
  структуры), а `ulist%` / `unode%` — новым словом `end-struct-const`
  (`over naligned nip constant`): обычная константа-размер одной
  ячейкой, как ждёт `X allocate`.
- Семантика размеров не изменилась: `unode% = 16`, `ulist% = 16`.

### Added
- `tests/fenum-stack_test.4th` — регрессионный тест: после
  `require ../fenum.4th` глубина data stack не изменилась; размеры
  `unode%` / `ulist%` / `container%`; чистота стека после `unode-new`.

## [0.1.2] - 2026-06-08

### Added
- `package.4th`: declare `fmix ~> 0.7`, `flint ~> 0.2`, `fcov ~> 0.3`.
- `AGENTS.md` and `.cursor/rules/vitasound-forth.mdc` for pre-commit
  flint/fcov workflow and vitasound-forth MCP.
- `.gitignore`: ignore `build/`, `forth-packages/`, `.fcov/`.

### Changed
- All `tests/*` and `tests/bs/*` require `ttester` 1.2.1 (was 1.1.0).
- `README.md`: document `flint` and `fcov run fmix test` in quality workflow.

## [0.1.1] - 2026-05-22

### Added
- `fenum-bs.4th` begin-structure backend for mixed Forth / fhdlgen projects.
- `tests/bs/` and `scripts/run-bs-tests.sh` for isolated bs-backend runs.

## [0.1.0]

Initial release: struct.fs backend, `ulist`, `enum-*` type-tag dispatcher.
