# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**climenu** is a lightweight R package that provides interactive command-line menu functionality, inspired by popular CLI tools like inquirer.js (JavaScript), pick (Python), and survey (Go).

The package enables R users to create intuitive, keyboard-navigable menus for selecting single or multiple items from a list, with graceful fallback for non-interactive environments.

## Key Features

- **Single selection menus** - Select one item with arrow key navigation
- **Multiple selection menus** - Checkbox-style interface for selecting multiple items
- **Keyboard navigation** - Arrow keys (↑/↓) or vi-style (j/k) navigation
- **Pre-selection support** - Start with items already selected
- **Return flexibility** - Return values or indices
- **Non-interactive fallback** - Works in batch mode with sensible defaults
- **Minimal dependencies** - Only requires `cli` package

## Package Structure

```
climenu/
├── R/                      # Package functions
│   ├── menu.R             # Main menu interface
│   ├── select.R           # Single selection implementation
│   ├── checkbox.R         # Multiple selection implementation
│   └── utils.R            # Shared utilities
├── tests/testthat/        # Test suite
├── man/                   # Documentation (auto-generated)
├── DESCRIPTION            # Package metadata
├── NAMESPACE              # Exports (auto-generated)
├── README.md              # User-facing documentation
└── CLAUDE.md              # This file
```

## Development Commands

The package uses a **Makefile** for all development tasks. This is the standard approach for modern R packages.

### Quick Start

```bash
make deps         # Install dependencies (first time)
make test         # Run test suite
make lint         # Lint code
make check        # Run R CMD check
make all          # Run all quality checks
```

### All Available Commands

```bash
make help          # Show all available commands
make install       # Install package locally
make test          # Run test suite
make test-file     # Run specific test (FILE=test-name.R)
make check         # Run R CMD check
make check-fast    # Run check without installation
make lint          # Lint package code
make document      # Generate documentation
make build         # Build source package
make clean         # Remove build artifacts
make coverage      # Generate test coverage
make style         # Auto-format code
make dev           # Load package interactively
make quick         # Quick cycle (document + test)
```

### Direct R Commands (Alternative)

If you prefer not to use Make:

```bash
R -e "devtools::install_deps(dependencies = TRUE)"
R -e "devtools::test()"
R -e "devtools::check()"
R -e "devtools::document()"
R -e "devtools::build()"
R -e "devtools::install()"
```

## Code Style

- **Formatting**: 2-space indentation, no line length limit
- **Naming**: `snake_case` for functions and variables
- **Documentation**: Roxygen2 with Markdown support
- **Messaging**: Use `cli::cli_*` functions for user communication
- **Terminal output**: Use base `cat()` for raw terminal control sequences

## Key Dependencies

### Required
- `cli` (>= 3.6.0) - For styled terminal output

### Suggested
- `keypress` - For true single-keypress capture (highly recommended for best UX)
- `testthat` (>= 3.0.0) - For testing
- `roxygen2` (>= 7.0.0) - For documentation

## Implementation Notes

### Keyboard Input

The package uses two modes for keyboard input:

1. **keypress mode** (best experience) - When the `keypress` package is available, arrow keys and single keypresses work natively
2. **readline mode** (fallback) - When `keypress` is not available, users type commands and press Enter

The `get_keypress()` function in `R/utils.R` handles this detection and fallback automatically.

### Terminal Control

The package uses ANSI escape sequences for terminal manipulation:
- `\033[<n>A` - Move cursor up n lines
- `\033[2K` - Clear current line

These sequences work in most modern terminals (macOS Terminal, iTerm2, Linux terminals, Windows Terminal, VSCode terminal).

### Menu Rendering

Menus are rendered by:
1. Printing the menu items with cursor and selection indicators
2. Reading user input
3. Clearing the previous menu
4. Re-rendering with updated state

This creates a "live" interactive experience.

## Testing

Run tests with:
```r
devtools::test()
```

The test suite covers:
- Input validation
- Pre-selection handling
- Non-interactive mode behavior
- Export verification
- Edge cases (empty selections, out-of-range indices)

## Commit Conventions

Follow Conventional Commits:
- `feat:` - New features
- `fix:` - Bug fixes
- `docs:` - Documentation changes
- `test:` - Test additions/changes
- `refactor:` - Code restructuring
- `chore:` - Maintenance tasks

## Important Reminders

- NEVER create files unless absolutely necessary
- ALWAYS prefer editing existing files to creating new ones
- NEVER proactively create documentation files unless explicitly requested
- Use `cli::cli_*` functions for user-facing messages
- Allow `cat()` for terminal control sequences (raw output)
- Keep the package lightweight - avoid heavy dependencies

## API Design Principles

1. **Simplicity** - Functions should be intuitive and require minimal configuration
2. **Consistency** - All menu types use similar parameters and return formats
3. **Flexibility** - Support both simple use cases and advanced configurations
4. **Robustness** - Graceful degradation in non-interactive environments
5. **Portability** - Work across different terminals and operating systems
