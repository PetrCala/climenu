# Repository Guidelines

## Project Structure & Module Organization
- `R/` contains the core package functions (`menu`, `select`, `checkbox`) and helpers.
- `tests/testthat/` holds unit tests; `tests/testthat.R` is the entry point for `testthat`.
- `man/` contains generated Rd documentation; `vignettes/` holds longer-form guides.
- `inst/` is for runtime assets bundled with the package.
- `DESCRIPTION` and `NAMESPACE` define package metadata and exports.
- `doc/` and `Meta/` are build artifacts produced by `R CMD check`.

## Build, Test, and Development Commands
- `make deps`: install R package dependencies via `devtools`.
- `make install`: install the package locally.
- `make test`: run all tests with `devtools::test()`.
- `make test-file FILE=test-climenu.R`: run a single test file.
- `make lint`: lint the package with `lintr::lint_package()`.
- `make document`: regenerate Rd docs with `roxygen2`.
- `make check`: run `devtools::check()` (full `R CMD check`).
- `make build`: build the source tarball.
- `make style`: auto-format with `styler::style_pkg()`.
- `make all` or `make quick`: run the common quality gates.

## Coding Style & Naming Conventions
- Use 2-space indentation and `snake_case` for functions/variables.
- Document exported functions with roxygen2 (`@export`, `@examples`).
- Prefer `cli::cli_*` for user-facing messages.
- Run `make style` before submitting changes; resolve `make lint` issues.

## Testing Guidelines
- Tests use `testthat`; name files `test-*.R` and use `test_that("description", { ... })`.
- Place new tests alongside similar coverage in `tests/testthat/`.
- Run `make test` before PRs; use `make coverage` if coverage needs review.

## Commit & Pull Request Guidelines
- Follow Conventional Commits: `feat:`, `fix:`, `docs:`, `test:`, `refactor:`, `chore:`.
- Example: `feat: add preselection for checkbox menu`.
- PRs should include a clear summary, linked issues (if any), and updated docs.
- Ensure `make lint`, `make test`, and `make check` pass; avoid reducing coverage.

## Configuration Tips
- Required dependencies: `cli` and `keypress`; keep the numbered-prompt fallbacks intact for environments without single-key or ANSI support.
- Avoid adding heavyweight dependencies without maintainers’ approval.
