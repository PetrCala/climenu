# climenu 0.2.0

* Named `choices` separate display text from return values: the names are the labels shown in the menu and the (unnamed) values are what `select()`, `checkbox()`, and `menu()` return. Character `selected` values match the returned values first, then the labels. Unnamed vectors behave exactly as before.
* New `descriptions` parameter on `select()`, `checkbox()`, and `menu()`: an optional per-choice character vector rendered dim after each label as an aligned second column, in both the live menu and the numbered fallback. Descriptions are display-only and are never echoed or returned.
* The confirmation echo prints the plain label instead of passing it through `{.val}`. Labels that carry ANSI styling no longer surface as literal `\033[90m...` text wrapped in quotes.
* New `echo` parameter on `select()`, `checkbox()`, and `menu()` to suppress the confirmation summary after a completed selection.
* Numbered fallback menus truncate their rows to the console width, matching the live menu.
* The one-time fallback notice no longer misattributes the cause: live menus need both single-key input and ANSI escapes, and the fallback engages when either is missing.
* Live menus no longer flicker while navigating: each keystroke repaints the frame in one atomic write instead of erasing and redrawing line by line, the text cursor is hidden while the menu is on screen, and redraws are wrapped in synchronized-output guards for terminals that support them.

# climenu 0.1.8

* Esc now cancels live menus on every platform. Previously the key was ignored and only `q` cancelled.
* Menus fall back to numbered-prompt mode on terminals without ANSI escape support, so single-key-capable but non-VT consoles (for example legacy Windows consoles) no longer render a broken live menu.
* Menu symbols degrade to ASCII on non-UTF-8 terminals, and rendered lines are truncated to the console width so wrapped rows cannot corrupt the redraw.
* `select()` now honors the preselected default in non-interactive sessions.
* `menu()` validates `max_visible` and forwards `max_visible` and `allow_select_all` to the underlying menu.

# climenu 0.1.7

* Initial CRAN release.
