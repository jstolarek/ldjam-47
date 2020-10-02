Controls
========

  * `Alt + Enter` / `F11` - toggle fullscreen

In devel mode
-------------

  * `Num Enter` - pause/unpause
  * `Num +` / `Num -` - increase/decrease game speed
  * `Num 0` (when paused) - advance simulation by one frame
  * `~` - show/hide development console

Development console flags
-------------------------

Flags can be set with command `+ flag_name` and unset with `- flag_name`.

  * `fps` (default: unset) - show/hide FPS counter
  * `labels` (default: unset) - show/hide debug labels on entities
  * `debug` (default: set) - when set the debug output from loggers is always
    displayed.  When unset it is only displayed when the development console is
    active.
  * `focus` (default: set) - should console have exclusive focus?  If set then
   player input actions are not registered when console is open, so it is
   possible to press arrows without moving the player entity.
