# Change Log

All notable changes to fenum are documented here.

The format is based on [Keep a Changelog](http://keepachangelog.com/) and
this project adheres to [Semantic Versioning](http://semver.org/).

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
