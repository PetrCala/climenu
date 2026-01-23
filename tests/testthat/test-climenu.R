test_that("validate_choices works correctly", {
  # Valid choices
  expect_silent(climenu:::validate_choices(c("a", "b", "c")))

  # Invalid: not character
  expect_error(climenu:::validate_choices(1:3), "must be a character vector")

  # Invalid: empty
  expect_error(climenu:::validate_choices(character(0)), "at least one element")

  # Invalid: contains NA
  expect_error(climenu:::validate_choices(c("a", NA, "c")), "must not contain NA")
})

test_that("normalize_selected handles numeric indices", {
  choices <- c("A", "B", "C", "D")

  # Valid single index
  expect_equal(climenu:::normalize_selected(2, choices, multiple = FALSE), 2L)

  # Valid multiple indices
  expect_equal(climenu:::normalize_selected(c(1, 3), choices, multiple = TRUE), c(1L, 3L))

  # Out of range - warns and filters
  expect_warning(result <- climenu:::normalize_selected(c(1, 5), choices, multiple = TRUE))
  expect_equal(result, 1L)

  # Multiple for single-select - warns and takes first
  expect_warning(result <- climenu:::normalize_selected(c(1, 2), choices, multiple = FALSE))
  expect_equal(result, 1L)
})

test_that("normalize_selected handles character values", {
  choices <- c("Apple", "Banana", "Cherry")

  # Valid single value
  expect_equal(climenu:::normalize_selected("Banana", choices, multiple = FALSE), 2L)

  # Valid multiple values
  expect_equal(climenu:::normalize_selected(c("Apple", "Cherry"), choices, multiple = TRUE), c(1L, 3L))

  # Not found - warns
  expect_warning(result <- climenu:::normalize_selected("Orange", choices, multiple = TRUE))
  expect_null(result)
})

test_that("normalize_selected handles NULL", {
  choices <- c("A", "B", "C")

  expect_null(climenu:::normalize_selected(NULL, choices, multiple = FALSE))
  expect_null(climenu:::normalize_selected(NULL, choices, multiple = TRUE))
})

test_that("menu function validates type parameter", {
  choices <- c("A", "B", "C")

  # Invalid type
  expect_error(climenu::menu(choices, type = "invalid"), "'arg' should be one of")
})

test_that("select returns NULL in non-interactive mode", {
  choices <- c("Option 1", "Option 2", "Option 3")

  # In non-interactive mode, should warn and return first choice
  expect_warning(result <- climenu::select(choices), "Not running in interactive mode")

  # Should return first choice
  expect_equal(result, "Option 1")
})

test_that("checkbox returns NULL in non-interactive mode", {
  choices <- c("Option 1", "Option 2", "Option 3")

  # Without pre-selection
  expect_warning(result <- climenu::checkbox(choices), "Not running in interactive mode")
  expect_equal(result, character(0))

  # With pre-selection
  expect_warning(
    result <- climenu::checkbox(choices, selected = c(1, 2)),
    "Not running in interactive mode"
  )
  expect_equal(result, c("Option 1", "Option 2"))
})

test_that("return_index parameter works", {
  choices <- c("A", "B", "C")

  # select with return_index
  expect_warning(result <- climenu::select(choices, return_index = TRUE))
  expect_equal(result, 1L)

  # checkbox with return_index
  expect_warning(result <- climenu::checkbox(choices, selected = c(1, 3), return_index = TRUE))
  expect_equal(result, c(1L, 3L))
})

test_that("render_menu creates correct output", {
  choices <- c("A", "B", "C")

  # Capture output for select type
  output <- capture.output(
    lines <- climenu:::render_menu(choices, cursor_pos = 2, selected_indices = NULL, type = "select")
  )

  expect_length(lines, 3)
  expect_length(output, 3)

  # Capture output for checkbox type
  output <- capture.output(
    lines <- climenu:::render_menu(choices, cursor_pos = 1, selected_indices = c(1, 3), type = "checkbox")
  )

  expect_length(lines, 3)
  expect_length(output, 3)
})

test_that("checkbox handles empty selection", {
  choices <- c("A", "B", "C")

  # No pre-selection in non-interactive mode
  expect_warning(result <- climenu::checkbox(choices))
  expect_equal(result, character(0))
  expect_length(result, 0)
})

test_that("menu exports all expected functions", {
  # Check that functions are exported successfully
  expect_true(is.function(climenu::menu))
  expect_true(is.function(climenu::checkbox))
  expect_true(is.function(climenu::select))
})

# Tests for select all feature
test_that("allow_select_all = FALSE maintains backward compatibility", {
  choices <- c("A", "B", "C")

  # Should work exactly as before
  expect_warning(result <- climenu::checkbox(choices, allow_select_all = FALSE))
  expect_equal(result, character(0))

  # With pre-selection
  expect_warning(
    result <- climenu::checkbox(choices, selected = c(1, 2), allow_select_all = FALSE),
    "Not running in interactive mode"
  )
  expect_equal(result, c("A", "B"))
})

test_that("allow_select_all parameter validation", {
  choices <- c("A", "B", "C")

  # Invalid: not logical
  expect_error(
    climenu::checkbox(choices, allow_select_all = "yes"),
    "allow_select_all must be a single logical value"
  )

  # Invalid: NA
  expect_error(
    climenu::checkbox(choices, allow_select_all = NA),
    "allow_select_all must be a single logical value"
  )

  # Invalid: multiple values
  expect_error(
    climenu::checkbox(choices, allow_select_all = c(TRUE, FALSE)),
    "allow_select_all must be a single logical value"
  )
})

test_that("render_menu displays select all option when enabled", {
  choices <- c("A", "B", "C")

  # Test with select all enabled
  output <- capture.output(
    lines <- climenu:::render_menu(
      choices = choices,
      cursor_pos = 1,
      selected_indices = c(1, 2),
      type = "checkbox",
      allow_select_all = TRUE,
      select_all_text = "Select all"
    )
  )

  # Should have 4 lines: special option + 3 choices
  expect_length(lines, 4)
  expect_length(output, 4)

  # First line should contain "Select all"
  expect_true(grepl("Select all", lines[1]))
  expect_true(grepl("Select all", output[1]))
})

test_that("render_menu shows Deselect all when all items selected", {
  choices <- c("A", "B", "C")

  # Test with all items selected
  output <- capture.output(
    lines <- climenu:::render_menu(
      choices = choices,
      cursor_pos = 1,
      selected_indices = c(1, 2, 3),
      type = "checkbox",
      allow_select_all = TRUE,
      select_all_text = "Deselect all"
    )
  )

  # First line should contain "Deselect all"
  expect_true(grepl("Deselect all", lines[1]))
  expect_true(grepl("Deselect all", output[1]))
})

test_that("checkbox with allow_select_all in non-interactive mode", {
  choices <- c("A", "B", "C")

  # Without pre-selection
  expect_warning(
    result <- climenu::checkbox(choices, allow_select_all = TRUE),
    "Not running in interactive mode"
  )
  expect_equal(result, character(0))

  # With pre-selection - should return only real choices, not special option
  expect_warning(
    result <- climenu::checkbox(choices, selected = c(1, 2), allow_select_all = TRUE),
    "Not running in interactive mode"
  )
  expect_equal(result, c("A", "B"))
  expect_false("Select all" %in% result)
  expect_false("Deselect all" %in% result)
})

test_that("checkbox with allow_select_all and return_index", {
  choices <- c("A", "B", "C")

  # Should return indices of real choices only
  expect_warning(
    result <- climenu::checkbox(
      choices,
      selected = c(1, 3),
      allow_select_all = TRUE,
      return_index = TRUE
    ),
    "Not running in interactive mode"
  )
  expect_equal(result, c(1L, 3L))
  expect_true(all(result %in% seq_along(choices)))
})

test_that("checkbox select all works with all items pre-selected", {
  choices <- c("A", "B", "C")

  # All items pre-selected
  expect_warning(
    result <- climenu::checkbox(
      choices,
      selected = c(1, 2, 3),
      allow_select_all = TRUE
    ),
    "Not running in interactive mode"
  )
  expect_equal(result, c("A", "B", "C"))
  expect_length(result, 3)
})

test_that("checkbox select all works with empty selection", {
  choices <- c("A", "B", "C")

  # No items selected
  expect_warning(
    result <- climenu::checkbox(choices, allow_select_all = TRUE),
    "Not running in interactive mode"
  )
  expect_equal(result, character(0))
  expect_length(result, 0)
})

test_that("render_menu handles cursor position correctly with select all", {
  choices <- c("A", "B", "C")

  # Cursor on special option (position 1)
  output <- capture.output(
    lines <- climenu:::render_menu(
      choices = choices,
      cursor_pos = 1,
      selected_indices = c(1, 2),
      type = "checkbox",
      allow_select_all = TRUE,
      select_all_text = "Select all"
    )
  )

  # First line should be highlighted (cursor on it)
  expect_true(grepl("Select all", lines[1]))

  # Cursor on first real choice (position 2)
  output2 <- capture.output(
    lines2 <- climenu:::render_menu(
      choices = choices,
      cursor_pos = 2,
      selected_indices = c(1, 2),
      type = "checkbox",
      allow_select_all = TRUE,
      select_all_text = "Select all"
    )
  )

  # Second line should be highlighted (first real choice)
  expect_true(grepl("A", lines2[2]))
})
