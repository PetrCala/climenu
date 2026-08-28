# climenu - Interactive CLI Menus

A lightweight, standalone module for creating interactive command-line menus in R, inspired by:

- [inquirer.js](https://github.com/SBoudrias/Inquirer.js) (JavaScript)
- [pick](https://github.com/aisk/pick) (Python)
- [survey](https://github.com/AlecAivazis/survey) (Go)

## Features

- **Single selection** - Select one item from a list
- **Multiple selection** - Select multiple items with checkboxes
- **Keyboard navigation** - Arrow keys or vi-style (j/k) navigation
- **Scrollable menus** - Automatic pagination for long lists
- **Select all** - Optional toggle to select/deselect all items at once
- **Labels vs values** - Named choices display the names and return the values
- **Dim descriptions** - Optional aligned description column per choice
- **Pre-selection support** - Start with items already selected
- **Return flexibility** - Return values or indices
- **Minimal dependencies** - Only requires the `cli` and `keypress` packages

## Usage

### Installation

```r
install.packages("climenu")
```

### Basic Single Selection

```r
library(climenu)

colors <- c("Red", "Green", "Blue", "Yellow", "Purple")
selected <- menu(colors, prompt = "Choose your favorite color:")
# User navigates with ↑↓ or j/k, presses Enter to select
# Returns: "Blue" (for example)
```

### Multiple Selection (Checkbox)

```r
library(climenu)

toppings <- c("Pepperoni", "Mushrooms", "Olives", "Onions", "Extra Cheese")
selected <- menu(
  toppings,
  type = "checkbox",
  prompt = "Select pizza toppings:"
)
# User navigates with ↑↓, toggles with Space, confirms with Enter
# Returns: c("Pepperoni", "Extra Cheese", "Mushrooms")
```

### Pre-selection

```r
library(climenu)

# Pre-select by value
selected <- checkbox(
  choices = c("Option A", "Option B", "Option C"),
  selected = c("Option A", "Option C")
)

# Pre-select by index
selected <- checkbox(
  choices = c("Option A", "Option B", "Option C"),
  selected = c(1, 3),
  return_index = TRUE
)
# Returns: c(1, 2, 3) if user adds Option B
```

### Labels, Values, and Descriptions

```r
# Named choices: the names are displayed, the values are returned
action <- select(c("Run methods" = "run", "Quit" = "quit"))
# Menu shows "Run methods" / "Quit"; returns "run" or "quit"

# Dim, aligned descriptions after each label (display-only)
screen <- select(
  c("Studies", "Columns"),
  descriptions = c("per-study estimate counts", "role and type per column")
)
```

### Direct Function Calls

```r
library(climenu)

# Single selection
choice <- select(c("Yes", "No", "Maybe"))

# Multiple selection
choices <- checkbox(c("Item 1", "Item 2", "Item 3"))
```

## Keyboard Controls

| Key | Action |
|-----|--------|
| ↑ / k | Move up |
| ↓ / j | Move down |
| Space | Toggle selection (checkbox only) |
| Enter | Confirm selection |
| Esc / q | Cancel (returns NULL) |

On terminals that don't support single-key input or ANSI escape sequences (e.g. RStudio or RGui on Windows), `climenu` falls back to a numbered-prompt mode — type the number of your choice (or comma-separated numbers for checkboxes) and press Enter. On non-UTF-8 terminals, ASCII symbols are used instead of Unicode glyphs.

## API Reference

### `menu(choices, prompt, type, selected, return_index, max_visible, allow_select_all, descriptions, echo)`

Main entry point for creating menus.

**Parameters:**

- `choices` - Character vector of options. When named, the names are the displayed labels and the values are returned.
- `prompt` - Message to display (default: "Select an item:")
- `type` - "select" for single, "checkbox" for multiple (default: "select")
- `selected` - Pre-selected items (indices or values)
- `return_index` - Return indices instead of values (default: FALSE)
- `max_visible` - Maximum items to display at once (default: 10). Set to NULL to show all.
- `allow_select_all` - Add a "Select all" / "Deselect all" toggle at the top; checkbox type only (default: FALSE).
- `descriptions` - Optional per-choice character vector rendered dim after each label; display-only (default: NULL).
- `echo` - Print the confirmation line after a completed selection (default: TRUE).

**Returns:** Selected value(s) or NULL if cancelled

### `select(choices, prompt, selected, return_index, max_visible, descriptions, echo)`

Single selection menu. Same parameters as `menu()` (without `type`), plus:

- `max_visible` - Maximum items to display at once (default: 10). Set to NULL to show all.

### `checkbox(choices, prompt, selected, return_index, max_visible, allow_select_all, descriptions, echo)`

Multiple selection menu with checkboxes. Same parameters as `menu()` (without `type`), plus:

- `max_visible` - Maximum items to display at once (default: 10). Set to NULL to show all.
- `allow_select_all` - Add a "Select all" / "Deselect all" toggle at the top (default: FALSE).

## Development

### Quick Start

```bash
# Install dependencies
make deps

# Run tests
make test

# Lint code
make lint

# Run all checks
make all
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed development guidelines.

### Available Make Targets

```bash
make help          # Show all available commands
make install       # Install package locally
make test          # Run test suite
make check         # Run R CMD check
make lint          # Lint code
make document      # Generate documentation
make build         # Build source package
make coverage      # Generate test coverage report
make clean         # Remove build artifacts
make all           # Run all quality checks
```

## Design Philosophy

1. **Lightweight** - Minimal dependencies (only `cli` and `keypress`)
2. **Intuitive** - Familiar keyboard controls from other CLI tools
3. **Flexible** - Works as a standalone package or integrated into other packages
4. **Robust** - Graceful fallback for non-interactive environments

## Future Enhancements

- Autocomplete/search filtering
- Nested menus
- Custom styling/themes
- Input validation prompts
- Password prompts
- Progress bars

## Non-Interactive Behavior

When not running in an interactive R session, the menu functions:

- Issue a warning
- Return the first choice (select) or pre-selected items (checkbox)
- Do not block execution
