#!/usr/bin/env bash
# begin-structure backend — каждый файл в новом процессе Gforth.
set -euo pipefail
cd "$(dirname "$0")/.."
for t in tests/bs/fenum-ulist-bs_test.4th tests/bs/fenum-enum-bs_test.4th; do
  echo "== $t =="
  gforth -e "require ./$t bye"
done
echo "bs tests ok"
