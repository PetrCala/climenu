test_that("keypress_supported returns FALSE when has_keypress_support errors", {
  testthat::local_mocked_bindings(
    has_keypress_support = function() cli::cli_abort("no support"),
    .package = "keypress"
  )
  expect_false(climenu:::keypress_supported())
})

test_that("keypress_supported returns FALSE when has_keypress_support is FALSE", {
  testthat::local_mocked_bindings(
    has_keypress_support = function() FALSE,
    .package = "keypress"
  )
  expect_false(climenu:::keypress_supported())
})

test_that("keypress_supported returns TRUE when has_keypress_support is TRUE", {
  testthat::local_mocked_bindings(
    has_keypress_support = function() TRUE,
    .package = "keypress"
  )
  expect_true(climenu:::keypress_supported())
})

test_that("select_fallback returns chosen value for valid number", {
  testthat::local_mocked_bindings(read_line = function(prompt = "") "2")
  choices <- c("a", "b", "c")
  expect_message(
    result <- climenu:::select_fallback(choices, "Pick:", 1L, return_index = FALSE),
    "Selected"
  )
  expect_equal(result, "b")
})

test_that("select_fallback returns index when return_index = TRUE", {
  testthat::local_mocked_bindings(read_line = function(prompt = "") "3")
  choices <- c("a", "b", "c")
  result <- suppressMessages(
    climenu:::select_fallback(choices, "Pick:", 1L, return_index = TRUE)
  )
  expect_equal(result, 3L)
})

test_that("select_fallback uses default on empty input", {
  testthat::local_mocked_bindings(read_line = function(prompt = "") "")
  choices <- c("a", "b", "c")
  result <- suppressMessages(
    climenu:::select_fallback(choices, "Pick:", 2L, return_index = FALSE)
  )
  expect_equal(result, "b")
})

test_that("select_fallback returns NULL on 'q'", {
  testthat::local_mocked_bindings(read_line = function(prompt = "") "q")
  choices <- c("a", "b", "c")
  result <- suppressMessages(
    climenu:::select_fallback(choices, "Pick:", 1L, return_index = FALSE)
  )
  expect_null(result)
})

test_that("select_fallback retries once on invalid input then gives up", {
  inputs <- c("zzz", "xxx")
  i <- 0L
  testthat::local_mocked_bindings(read_line = function(prompt = "") {
    i <<- i + 1L
    inputs[i]
  })
  choices <- c("a", "b", "c")
  result <- suppressMessages(
    climenu:::select_fallback(choices, "Pick:", 1L, return_index = FALSE)
  )
  expect_null(result)
  expect_equal(i, 2L)
})

test_that("select_fallback accepts valid number after an invalid retry", {
  inputs <- c("99", "2")
  i <- 0L
  testthat::local_mocked_bindings(read_line = function(prompt = "") {
    i <<- i + 1L
    inputs[i]
  })
  choices <- c("a", "b", "c")
  result <- suppressMessages(
    climenu:::select_fallback(choices, "Pick:", 1L, return_index = FALSE)
  )
  expect_equal(result, "b")
})

test_that("checkbox_fallback toggles items via comma list", {
  testthat::local_mocked_bindings(read_line = function(prompt = "") "1,3")
  choices <- c("a", "b", "c")
  result <- suppressMessages(
    climenu:::checkbox_fallback(choices, "Pick:", integer(0), return_index = FALSE, allow_select_all = FALSE)
  )
  expect_equal(result, c("a", "c"))
})

test_that("checkbox_fallback returns indices when return_index = TRUE", {
  testthat::local_mocked_bindings(read_line = function(prompt = "") "2,3")
  choices <- c("a", "b", "c")
  result <- suppressMessages(
    climenu:::checkbox_fallback(choices, "Pick:", integer(0), return_index = TRUE, allow_select_all = FALSE)
  )
  expect_equal(result, c(2L, 3L))
})

test_that("checkbox_fallback empty input confirms pre-selected state", {
  testthat::local_mocked_bindings(read_line = function(prompt = "") "")
  choices <- c("a", "b", "c")
  result <- suppressMessages(
    climenu:::checkbox_fallback(choices, "Pick:", c(1L, 2L), return_index = FALSE, allow_select_all = FALSE)
  )
  expect_equal(result, c("a", "b"))
})

test_that("checkbox_fallback toggles off already-selected items", {
  testthat::local_mocked_bindings(read_line = function(prompt = "") "2")
  choices <- c("a", "b", "c")
  result <- suppressMessages(
    climenu:::checkbox_fallback(choices, "Pick:", c(1L, 2L), return_index = FALSE, allow_select_all = FALSE)
  )
  expect_equal(result, "a")
})

test_that("checkbox_fallback 'a' toggles all when allow_select_all = TRUE", {
  testthat::local_mocked_bindings(read_line = function(prompt = "") "a")
  choices <- c("a", "b", "c")
  result <- suppressMessages(
    climenu:::checkbox_fallback(choices, "Pick:", integer(0), return_index = FALSE, allow_select_all = TRUE)
  )
  expect_equal(result, c("a", "b", "c"))
})

test_that("checkbox_fallback 'a' deselects all when everything is selected", {
  testthat::local_mocked_bindings(read_line = function(prompt = "") "a")
  choices <- c("a", "b", "c")
  result <- suppressMessages(
    climenu:::checkbox_fallback(choices, "Pick:", 1:3, return_index = FALSE, allow_select_all = TRUE)
  )
  expect_equal(result, character(0))
})

test_that("checkbox_fallback returns NULL on 'q'", {
  testthat::local_mocked_bindings(read_line = function(prompt = "") "q")
  choices <- c("a", "b", "c")
  result <- suppressMessages(
    climenu:::checkbox_fallback(choices, "Pick:", integer(0), return_index = FALSE, allow_select_all = FALSE)
  )
  expect_null(result)
})

test_that("checkbox_fallback warns on out-of-range indices and ignores them", {
  testthat::local_mocked_bindings(read_line = function(prompt = "") "1,99")
  choices <- c("a", "b", "c")
  expect_message(
    result <- climenu:::checkbox_fallback(
      choices, "Pick:", integer(0),
      return_index = FALSE, allow_select_all = FALSE
    ),
    "out-of-range"
  )
  expect_equal(result, "a")
})

test_that("checkbox_fallback warns on non-numeric tokens and ignores them", {
  testthat::local_mocked_bindings(read_line = function(prompt = "") "1,foo")
  choices <- c("a", "b", "c")
  expect_message(
    result <- climenu:::checkbox_fallback(
      choices, "Pick:", integer(0),
      return_index = FALSE, allow_select_all = FALSE
    ),
    "non-numeric"
  )
  expect_equal(result, "a")
})
