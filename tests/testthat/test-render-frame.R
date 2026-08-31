# Atomic frame emission: one write per keystroke, no erase-then-repaint gap.

test_that("render_menu emits the frame as a single write of erase-prefixed rows", {
  out <- capture.output(
    lines <- climenu:::render_menu(c("A", "B"), cursor_pos = 1, selected_indices = NULL, type = "select")
  )
  expect_length(lines, 2)
  expect_true(all(startsWith(out, "\033[2K")))
})

test_that("render_menu replaces the previous frame inside synchronized-output guards", {
  raw <- paste(capture.output(
    lines <- climenu:::render_menu(
      c("A", "B"),
      cursor_pos = 2, selected_indices = NULL, type = "select",
      replace_lines = 2L
    )
  ), collapse = "\n")

  expect_true(startsWith(raw, "\033[?2026h\033[2A\r"))
  expect_true(endsWith(raw, "\033[?2026l"))
})

test_that("render_menu blanks leftover rows when the frame shrinks", {
  raw <- paste(capture.output(
    lines <- climenu:::render_menu(
      "A",
      cursor_pos = 1, selected_indices = NULL, type = "select",
      replace_lines = 3L
    )
  ), collapse = "\n")

  # Two leftover rows are erased and the cursor moves back up over them
  expect_true(grepl("\033[2K\n\033[2K\n\033[2A\033[?2026l", raw, fixed = TRUE))
})

test_that("clear_lines erases in a single write", {
  out <- capture.output(climenu:::clear_lines(2))
  expect_equal(out, "\033[1A\033[2K\033[1A\033[2K")
  expect_length(capture.output(climenu:::clear_lines(0)), 0)
})

test_that("cursor visibility helpers emit the expected sequences", {
  expect_equal(capture.output(climenu:::hide_cursor()), "\033[?25l")
  expect_equal(capture.output(climenu:::show_cursor()), "\033[?25h")
})
