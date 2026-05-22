\ fenum-bs.4th — точка входа для begin-structure backend
\
\ Используйте в проектах на begin-structure / field: (fhdlgen и др.).
\ Не require ./fenum.4th в том же образе Gforth — struct.fs ломает field:.

require ./fenum-types.4th
require ./fenum-ulist-bs.4th
require ./fenum-enum-core.4th

1 constant fenum-backend-bs
