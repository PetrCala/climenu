# climenu - Interactive CLI Menus for R

A lightweight, standalone module for creating interactive command-line menus in R, inspired by:

- [inquirer.js](https://github.com/SBoudrias/Inquirer.js) (JavaScript)
- [pick](https://github.com/wong2/pick) (Python)
- [survey](https://github.com/AlecAivazis/survey) (Go)

## Features

- **Single selection** - Select one item from a list
- **Multiple selection** - Select multiple items with checkboxes
- **Keyboard navigation** - Arrow keys or vi-style (j/k) navigation
- **Pre-selection support** - Start with items already selected
- **Return flexibility** - Return values or indices
- **Standalone design** - Can be extracted as its own package

## Usage

### Installation

```r
# Install from GitHub (until CRAN submission)
# install.packages("remotes")
remotes::install_github("PetrCala/climenu")
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

### Direct Function Calls

```r
library(climenu)

# Single selection
choice <- select(c("Yes", "No", "Maybe"))

# Multiple selection
choices <- checkbox(c("Item 1", "Item 2", "Item 3"))
```

## Keyboard Controls

### With `keypress` package (recommended)

| Key | Action |
|-----|--------|
| ↑ / k | Move up |
| ↓ / j | Move down |
| Space | Toggle selection (checkbox only) |
| Enter | Confirm selection |
| Esc / q | Cancel (returns NULL) |

### Without `keypress` (fallback mode)

Type commands and press Enter:
- `k` or `up` - Move up
- `j` or `down` - Move down
- `space` - Toggle selection (checkbox only)
- `<number>` - Jump to item number
- `<Enter>` - Confirm selection
- `q` or `quit` - Cancel

**Install `keypress` for the best experience:**
```r
install.packages("keypress")
```

## API Reference

### `menu(choices, prompt, type, selected, return_index)`

Main entry point for creating menus.

**Parameters:**

- `choices` - Character vector of options
- `prompt` - Message to display (default: "Select an item:")
- `type` - "select" for single, "checkbox" for multiple (default: "select")
- `selected` - Pre-selected items (indices or values)
- `return_index` - Return indices instead of values (default: FALSE)

**Returns:** Selected value(s) or NULL if cancelled

### `select(choices, prompt, selected, return_index)`

Single selection menu.

### `checkbox(choices, prompt, selected, return_index)`

Multiple selection menu with checkboxes.

## Design Philosophy

This module is designed to be:

1. **Standalone** - Minimal dependencies, can be extracted as its own package
2. **Intuitive** - Familiar keyboard controls from other CLI tools
3. **Flexible** - Works with the box module system or as a standalone package
4. **Robust** - Graceful fallback for non-interactive environments

## Future Enhancements

Potential additions when extracted as standalone package:

- Autocomplete/search filtering
- Nested menus
- Custom styling/themes
- Pagination for long lists
- Input validation prompts
- Password prompts
- Progress bars

## Non-Interactive Behavior

When not running in an interactive R session, the menu functions:

- Issue a warning
- Return the first choice (select) or pre-selected items (checkbox)
- Do not block execution
