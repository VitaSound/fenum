\ fenum-container.4th — базовый класс container
\
\ Универсальный интерфейс для всех контейнеров (ulist, hashmap, …):
\ полиморфные методы вызываются одинаково для любого подкласса.

require mini-oof2.fs
require stuff.fs

\ Сохраняем оригинальный mini-oof2 dispose: переопределение method'ом
\ затрёт глобальное имя в текущем словаре.
' dispose alias dispose-self  ( o:o -- o:0 )

object class
    method empty?      ( -- flag )
    method len         ( -- n )
    method add         ( addr -- )
    method contains?   ( addr -- flag )
    method nth-addr    ( n -- addr|0 )      \ 0-based
    method each        ( xt -- )            \ xt: ( addr -- )
    method clear       ( -- )               \ удалить содержимое
    method reverse     ( -- )               \ in-place; для неупорядоченных — noop
    method new-empty   ( -- new-container )
    method dispose     ( -- )               \ clear + освободить сам объект
end-class container

\ Возвращаем стандартный +field, чтобы обычные struct после class
\ работали правильно (mini-oof2 переключает +field на instance-var
\ и не восстанавливает его на end-class).
standard:field

\ Дефолтные реализации:

\ Дефолтный reverse — ничего не делает (для неупорядоченных коллекций).
container :method reverse ( -- ) ;

\ Дефолтный new-empty создаёт пустой объект ТОГО ЖЕ класса, что и self.
\ Использует layout mini-oof2: class-pointer лежит на (o - cell).
container :method new-empty ( -- new-container )
    o cell- @ new ;

\ Дефолтный dispose просто освобождает память объекта.
\ Наследники должны переопределить, если у них есть внутренние ресурсы
\ (как у ulist — цепочка allocate'нутых узлов).
container :method dispose ( -- )
    dispose-self ;
