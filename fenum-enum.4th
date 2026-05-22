\ fenum-enum.4th — Elixir-style общие операции над container'ами
\
\ Слова enum-* — это диспетчеры по obj-type. Каждое знает реализации
\ для известных типов и направляет вызов соответствующему ulist-*,
\ hashmap-* и т.д.
\
\ Стек-конвенция: контейнер всегда top.
\   xt c enum-each
\   xt c enum-sort

require ./fenum-container.4th
require ./fenum-ulist.4th
require ./fenum-enum-core.4th
