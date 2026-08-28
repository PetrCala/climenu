# Named choices (label/value separation), the descriptions column, and the
# confirmation-echo hygiene rules.

styled_label <- function(text) paste0("\033[90m", text, "\033[39m")

test_that("validate_choices rejects incomplete label sets on named vectors", {
  expect_silent(climenu:::validate_choices(c(A = "a", B = "b")))
  expect_error(
    climenu:::validate_choices(c(A = "a", "b")),
    "non-empty label for every choice"
  )
  expect_error(
    climenu:::validate_choices(stats::setNames(c("a", "b"), c("A", NA))),
    "non-empty label for every choice"
  )
})

test_that("resolve_choices splits labels from values", {
  parts <- climenu:::resolve_choices(c(A = "a", B = "b"))
  expect_equal(parts$labels, c("A", "B"))
  expect_equal(parts$values, c("a", "b"))

  parts <- climenu:::resolve_choices(c("a", "b"))
  expect_equal(parts$labels, c("a", "b"))
  expect_equal(parts$values, c("a", "b"))
})

test_that("descriptions are validated against the choices", {
  choices <- c("a", "b")
  expect_silent(climenu:::validate_descriptions(NULL, choices))
  expect_silent(climenu:::validate_descriptions(c("x", ""), choices))
  expect_error(
    climenu:::validate_descriptions("x", choices),
    "one entry per choice"
  )
  expect_error(
    climenu:::validate_descriptions(c("x", NA), choices),
    "must not contain NA"
  )
  expect_error(
    suppressWarnings(climenu::select(choices, descriptions = "x")),
    "one entry per choice"
  )
})

test_that("echo must be a single logical", {
  choices <- c("a", "b")
  expect_error(
    suppressWarnings(climenu::select(choices, echo = "yes")),
    "echo must be a single logical value"
  )
  expect_error(
    suppressWarnings(climenu::checkbox(choices, echo = NA)),
    "echo must be a single logical value"
  )
})

test_that("select returns values for named choices in non-interactive mode", {
  choices <- c("Run methods" = "run", "Quit" = "quit")

  expect_warning(result <- climenu::select(choices), "Not running in interactive mode")
  expect_equal(result, "run")

  expect_warning(result <- climenu::select(choices, selected = "quit"))
  expect_equal(result, "quit")
})

test_that("checkbox returns values for named choices in non-interactive mode", {
  choices <- c(A = "a", B = "b", C = "c")

  expect_warning(result <- climenu::checkbox(choices, selected = c("a", "c")))
  expect_equal(result, c("a", "c"))
})

test_that("character selected matches values first, then labels", {
  choices <- c(A = "a", B = "b")
  expect_equal(climenu:::normalize_selected("b", choices, multiple = FALSE), 2L)
  expect_equal(climenu:::normalize_selected("B", choices, multiple = FALSE), 2L)
  expect_warning(
    result <- climenu:::normalize_selected("nope", choices, multiple = FALSE),
    "None of the selected"
  )
  expect_null(result)
})

test_that("select_fallback displays labels and returns values", {
  testthat::local_mocked_bindings(read_line = function(prompt = "") "2")
  labels <- c("Run methods", "Quit")
  values <- c("run", "quit")

  output <- capture.output(
    messages <- testthat::capture_messages(
      result <- climenu:::select_fallback(labels, values, "Pick:", 1L, return_index = FALSE)
    )
  )

  expect_equal(result, "quit")
  expect_true(any(grepl("Run methods", output, fixed = TRUE)))
  expect_true(any(grepl("Quit", messages, fixed = TRUE)))
  expect_false(any(grepl("quit", messages, fixed = TRUE)))
})

test_that("checkbox_fallback displays labels and returns values", {
  testthat::local_mocked_bindings(read_line = function(prompt = "") "1,3")
  labels <- c("Alpha", "Beta", "Gamma")
  values <- c("a", "b", "c")

  result <- suppressMessages(capture.output(
    out <- climenu:::checkbox_fallback(
      labels, values, "Pick:", integer(0),
      return_index = FALSE, allow_select_all = FALSE
    )
  ))
  expect_equal(out, c("a", "c"))
})

test_that("the confirmation echo never leaks escape bytes or quotes", {
  testthat::local_mocked_bindings(read_line = function(prompt = "") "1")
  labels <- paste("Studies  ", styled_label("per-study estimate counts"))

  suppressMessages(capture.output(
    messages <- testthat::capture_messages(
      climenu:::select_fallback(labels, labels, "Pick:", 1L, return_index = FALSE)
    )
  ))

  echoed <- paste(messages, collapse = "\n")
  expect_true(grepl("per-study estimate counts", echoed, fixed = TRUE))
  # The reported bug: {.val} escaped the label's ANSI bytes into literal
  # "\033[90m" text and wrapped the label in quotes
  expect_false(grepl("\\033", echoed, fixed = TRUE))
  expect_false(grepl("\033[90m", echoed, fixed = TRUE))
  expect_false(grepl('"', echoed, fixed = TRUE))
})

test_that("the checkbox summary strips styling from labels", {
  labels <- c(styled_label("Alpha"), "Beta")

  messages <- testthat::capture_messages(
    climenu:::echo_checkbox_summary(labels, c(2L, 1L), echo = TRUE)
  )
  echoed <- paste(messages, collapse = "\n")

  expect_true(grepl("Selected 2 items", echoed, fixed = TRUE))
  expect_true(grepl("Alpha", echoed, fixed = TRUE))
  expect_false(grepl("\\033", echoed, fixed = TRUE))
  expect_false(grepl("\033[90m", echoed, fixed = TRUE))
  expect_false(grepl('"', echoed, fixed = TRUE))
})

test_that("echo = FALSE silences the confirmation but keeps the result", {
  testthat::local_mocked_bindings(read_line = function(prompt = "") "2")
  labels <- c("Alpha", "Beta")

  suppressMessages(capture.output(
    messages <- testthat::capture_messages(
      result <- climenu:::select_fallback(
        labels, labels, "Pick:", 1L,
        return_index = FALSE, echo = FALSE
      )
    )
  ))
  expect_equal(result, "Beta")
  expect_false(any(grepl("Selected", messages, fixed = TRUE)))

  expect_no_message(climenu:::echo_checkbox_summary(labels, 1L, echo = FALSE))
})

test_that("render_menu aligns the dim description column", {
  output <- capture.output(
    lines <- climenu:::render_menu(
      c("ab", "c"),
      cursor_pos = 1, selected_indices = NULL, type = "select",
      descriptions = c("first", "second")
    )
  )

  plain <- cli::ansi_strip(lines)
  expect_true(grepl("ab  first$", plain[1]))
  expect_true(grepl("c   second$", plain[2]))
})

test_that("render_menu skips the description column for empty entries", {
  output <- capture.output(
    lines <- climenu:::render_menu(
      c("ab", "c"),
      cursor_pos = 1, selected_indices = NULL, type = "select",
      descriptions = c("first", "")
    )
  )

  plain <- cli::ansi_strip(lines)
  expect_true(grepl("ab  first$", plain[1]))
  expect_true(grepl("c$", plain[2]))
})

test_that("descriptions render dim and outside the cursor highlight", {
  testthat::local_mocked_bindings(
    num_ansi_colors = function(...) 256L,
    .package = "cli"
  )

  output <- capture.output(
    lines <- climenu:::render_menu(
      c("ab", "c"),
      cursor_pos = 1, selected_indices = NULL, type = "select",
      descriptions = c("first", "second")
    )
  )

  # The cursor line closes the cyan highlight before the grey description
  # starts, so the mid-line reset in a styled label cannot bleed into it
  expect_true(grepl("\033[90mfirst\033[39m", lines[1], fixed = TRUE))
  expect_true(grepl("\033[90msecond\033[39m", lines[2], fixed = TRUE))
  cyan_part <- sub("\033\\[90m.*$", "", lines[1])
  expect_true(grepl("\033[36m", cyan_part, fixed = TRUE))
  expect_true(grepl("\033[39m", cyan_part, fixed = TRUE))
})

test_that("compose_menu_rows pads only rows that carry a description", {
  rows <- climenu:::compose_menu_rows(c("ab", "c"), c("first", ""))
  plain <- cli::ansi_strip(rows)
  expect_equal(plain[1], "ab  first")
  expect_equal(plain[2], "c")

  expect_equal(climenu:::compose_menu_rows(c("ab", "c"), NULL), c("ab", "c"))
})

test_that("fallback rows are truncated to the console width", {
  testthat::local_mocked_bindings(
    console_width = function(...) 12L,
    .package = "cli"
  )
  testthat::local_mocked_bindings(read_line = function(prompt = "") "q")

  long_label <- paste(rep("x", 40), collapse = "")
  suppressMessages(
    output <- capture.output(
      climenu:::select_fallback(long_label, long_label, "Pick:", 1L, return_index = FALSE)
    )
  )

  expect_true(all(cli::ansi_nchar(output) <= 12))

  testthat::local_mocked_bindings(read_line = function(prompt = "") "")
  suppressMessages(
    output <- capture.output(
      climenu:::checkbox_fallback(
        long_label, long_label, "Pick:", integer(0),
        return_index = FALSE, allow_select_all = FALSE
      )
    )
  )
  expect_true(all(cli::ansi_nchar(output) <= 12))
})

test_that("select_fallback keeps the default marker after the description", {
  testthat::local_mocked_bindings(read_line = function(prompt = "") "q")

  suppressMessages(
    output <- capture.output(
      climenu:::select_fallback(
        c("Alpha", "Beta"), c("a", "b"), "Pick:", 2L,
        return_index = FALSE, descriptions = c("one", "two")
      )
    )
  )

  plain <- cli::ansi_strip(output)
  expect_true(any(grepl("Alpha  one", plain, fixed = TRUE)))
  expect_true(any(grepl("Beta   two [default]", plain, fixed = TRUE)))
})
