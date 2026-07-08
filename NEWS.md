# climenu 0.1.8

* Esc now cancels live menus on every platform. Previously the key was ignored and only `q` cancelled.
* Menus fall back to numbered-prompt mode on terminals without ANSI escape support, so single-key-capable but non-VT consoles (for example legacy Windows consoles) no longer render a broken live menu.
* Menu symbols degrade to ASCII on non-UTF-8 terminals, and rendered lines are truncated to the console width so wrapped rows cannot corrupt the redraw.
* `select()` now honors the preselected default in non-interactive sessions.
* `menu()` validates `max_visible` and forwards `max_visible` and `allow_select_all` to the underlying menu.

# climenu 0.1.7

* Initial CRAN release.
