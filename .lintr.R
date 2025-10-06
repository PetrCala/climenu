# Linter configuration for climenu package

linters <- lintr::linters_with_defaults(
  # Set indentation to 2 spaces
  indentation_linter = lintr::indentation_linter(indent = 2),
  # Check that all commas are followed by spaces, but do not have spaces before them
  commas_linter = lintr::commas_linter(allow_trailing = FALSE),
  # Object naming conventions
  object_name_linter = lintr::object_name_linter(
    styles = c("snake_case", "dotted.case")
  ),
  object_length_linter = lintr::object_length_linter(length = 40),
  # No line length limit
  line_length_linter = NULL,
  # Disable commented code linter
  commented_code_linter = NULL,
  # Prefer cli functions over base messaging
  undesirable_function_linter = lintr::undesirable_function_linter(
    fun = lintr::modify_defaults(
      defaults = lintr::default_undesirable_functions,
      print = "use cli::cli_inform()",
      cat = NULL,  # Allow cat for terminal output
      message = "use cli::cli_inform()",
      warning = "use cli::cli_warn()",
      stop = "use cli::cli_abort()"
    )
  ),
  # Check for missing packages in namespace calls
  namespace_linter = lintr::namespace_linter()
)

exclusions <- list(
  "examples/"
)
