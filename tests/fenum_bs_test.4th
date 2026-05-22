\ begin-structure backend: отдельный процесс Gforth (struct.fs несовместим в одном образе).

s" scripts/run-bs-tests.sh" system
$? 0<> [IF] cr ." fenum_bs_test: bs suite failed" cr 1 throw [THEN]
