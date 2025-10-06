# Contributing to climenu

Thank you for considering contributing to climenu! This document provides guidelines and instructions for contributing.

## Development Setup

### Prerequisites

- R (>= 4.0.0)
- Git
- Make (optional but recommended)

### Initial Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/PetrCala/climenu.git
   cd climenu
   ```

2. Install dependencies:
   ```bash
   make deps
   # or
   Rscript -e "devtools::install_deps(dependencies = TRUE)"
   ```

3. Install the package locally:
   ```bash
   make install
   # or
   Rscript -e "devtools::install()"
   ```

## Development Workflow

### Using Make (Recommended)

The package includes a Makefile with common development tasks:

```bash
make help          # Show all available commands
make test          # Run tests
make lint          # Lint code
make check         # Run R CMD check
make document      # Generate documentation
make all           # Run all quality checks
```

### Quick Development Cycle

```bash
# Make changes to code...
make quick         # Document + test
```

### Running Tests

```bash
# Run all tests
make test

# Run specific test file
make test-file FILE=test-climenu.R

# Run tests in R
R -e "devtools::test()"
```

### Code Style

- Use 2-space indentation
- Use `snake_case` for function and variable names
- Keep functions focused and well-documented
- Use `cli::cli_*` for user-facing messages
- Run `make style` to auto-format code

### Linting

```bash
make lint
```

Fix any linting errors before submitting a pull request.

### Documentation

- Document all exported functions with roxygen2
- Include examples in `@examples`
- Update README.md if adding user-facing features
- Run `make document` after changing documentation

## Testing

- Write tests for all new features
- Ensure existing tests pass
- Aim for high test coverage
- Tests are located in `tests/testthat/`

### Test Structure

```r
test_that("descriptive test name", {
  # Arrange
  input <- c("A", "B", "C")

  # Act
  result <- climenu::select(input)

  # Assert
  expect_true(is.character(result) || is.null(result))
})
```

## Pull Request Process

1. **Create a branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**
   - Write code
   - Add tests
   - Update documentation
   - Run `make all` to verify

3. **Commit your changes**
   - Follow [Conventional Commits](https://www.conventionalcommits.org/)
   - Examples:
     - `feat: add search filtering to menus`
     - `fix: handle empty choices array`
     - `docs: update README with new examples`
     - `test: add tests for pre-selection`

4. **Push and create PR**
   ```bash
   git push origin feature/your-feature-name
   ```
   Then create a pull request on GitHub.

5. **PR Requirements**
   - All tests must pass
   - Code must pass linting
   - R CMD check must pass
   - Coverage should not decrease
   - Documentation is updated

## Commit Message Guidelines

We use [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` - New features
- `fix:` - Bug fixes
- `docs:` - Documentation changes
- `test:` - Test additions/changes
- `refactor:` - Code restructuring
- `style:` - Formatting changes
- `chore:` - Maintenance tasks
- `perf:` - Performance improvements

## Code of Conduct

- Be respectful and inclusive
- Welcome newcomers
- Focus on constructive feedback
- Prioritize the project's goals

## Questions?

- Open an issue for bugs or feature requests
- Tag maintainers for urgent matters
- Check existing issues before creating new ones

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

## Resources

- [R Packages Book](https://r-pkgs.org/)
- [devtools documentation](https://devtools.r-lib.org/)
- [testthat documentation](https://testthat.r-lib.org/)
- [roxygen2 documentation](https://roxygen2.r-lib.org/)
