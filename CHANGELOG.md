# Change Log

All notable changes to fenum are documented here.

The format is based on [Keep a Changelog](http://keepachangelog.com/) and
this project adheres to [Semantic Versioning](http://semver.org/).

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
