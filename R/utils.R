climenu_env <- new.env(parent = emptyenv())

#' Wrapper around base `readline` to allow mocking in tests
#' @keywords internal
#' @noRd
read_line <- function(prompt = "") {
  readline(prompt = prompt)
}

#' Check whether the current terminal supports single-key input
#' @keywords internal
#' @noRd
keypress_supported <- function() {
  tryCatch(
    isTRUE(keypress::has_keypress_support()),
    error = function(e) FALSE
  )
}

#' Check whether the current terminal understands ANSI escape sequences
#'
#' Keypress support and ANSI support are independent: legacy Windows
#' consoles can read single keys yet print escape sequences literally.
#' Color support implies working VT processing, so use cli's detection.
#' @keywords internal
#' @noRd
ansi_supported <- function() {
  isTRUE(cli::num_ansi_colors() > 1L)
}

#' Emit a one-time info message explaining the fallback
#' @keywords internal
#' @noRd
notify_fallback_once <- function() {
  if (isTRUE(climenu_env$fallback_notice_shown)) {
    return(invisible())
  }
  cli::cli_alert_info(
    "Your terminal does not support live menus (single-key input and ANSI escapes, e.g. RStudio or RGui on Windows). Using numbered-prompt mode."
  )
  climenu_env$fallback_notice_shown <- TRUE
  invisible()
}

#' Validate choices parameter
#' @keywords internal
#' @noRd
validate_choices <- function(choices) {
  if (!is.character(choices)) {
    cli::cli_abort("choices must be a character vector")
  }
  if (length(choices) == 0) {
    cli::cli_abort("choices must have at least one element")
  }
  if (any(is.na(choices))) {
    cli::cli_abort("choices must not contain NA values")
  }
}

#' Validate max_visible parameter
#' @keywords internal
#' @noRd
validate_max_visible <- function(max_visible) {
  if (is.null(max_visible)) {
    return(invisible())
  }
  if (!is.numeric(max_visible) || length(max_visible) != 1 ||
        is.na(max_visible) || max_visible < 1) {
    cli::cli_abort("max_visible must be NULL or a single number >= 1")
  }
  invisible()
}

#' Normalize selected parameter to indices
#' @keywords internal
#' @noRd
normalize_selected <- function(selected, choices, multiple = FALSE) {
  if (is.null(selected)) {
    return(NULL)
  }

  if (is.numeric(selected)) {
    indices <- as.integer(selected)
    if (any(indices < 1 | indices > length(choices))) {
      cli::cli_warn("Some selected indices are out of range. Ignoring.")
      indices <- indices[indices >= 1 & indices <= length(choices)]
    }
  } else if (is.character(selected)) {
    indices <- which(choices %in% selected)
    if (length(indices) == 0) {
      cli::cli_warn("None of the selected values found in choices. Ignoring.")
      return(NULL)
    }
  } else {
    cli::cli_abort("selected must be numeric (indices) or character (values)")
  }

  if (!multiple && length(indices) > 1) {
    cli::cli_warn("Multiple items selected for single-select menu. Using first.")
    indices <- indices[1]
  }

  return(indices)
}

#' Menu glyphs, with ASCII fallbacks for non-UTF-8 terminals
#' @keywords internal
#' @noRd
menu_symbols <- function() {
  if (cli::is_utf8_output()) {
    list(
      pointer = "\u276f", # <U+276F>
      checkbox_on = "\u2611", # <U+2611>
      checkbox_off = "\u2610", # <U+2610>
      arrow_up = "\u2191", # <U+2191>
      arrow_down = "\u2193" # <U+2193>
    )
  } else {
    list(
      pointer = ">",
      checkbox_on = "[x]",
      checkbox_off = "[ ]",
      arrow_up = "^",
      arrow_down = "v"
    )
  }
}

#' Render menu display
#' @keywords internal
#' @noRd
render_menu <- function(choices, cursor_pos, selected_indices, type = c("select", "checkbox"),
                        window_offset = 1L, max_visible = NULL, allow_select_all = FALSE,
                        select_all_text = NULL) {
  type <- match.arg(type)

  syms <- menu_symbols()
  # Truncate to the terminal width so each menu entry occupies exactly one
  # physical row; wrapped rows would break the cursor-up redraw in clear_lines()
  width <- cli::console_width()

  n_choices <- length(choices)
  effective_length <- if (allow_select_all) n_choices + 1L else n_choices

  # Determine visible range (accounting for special option if enabled)
  if (is.null(max_visible) || max_visible >= effective_length) {
    # Show all items (backward compatible)
    visible_start <- 1L
    visible_end <- effective_length
  } else {
    visible_start <- window_offset
    visible_end <- min(window_offset + max_visible - 1L, effective_length)
  }

  # Track lines for clearing later
  lines <- character(0)

  emit_line <- function(line) {
    line <- cli::ansi_strtrim(line, width)
    cat(line, "\n", sep = "")
    line
  }

  # Show indicator if there are items above
  items_above <- visible_start - 1L
  if (items_above > 0) {
    indicator <- cli::col_silver(sprintf("%s %d more above", syms$arrow_up, items_above))
    lines <- c(lines, emit_line(indicator))
  }

  # Render visible items
  for (pos in visible_start:visible_end) {
    is_cursor <- pos == cursor_pos
    cursor_mark <- if (is_cursor) syms$pointer else " "

    # Handle special select all option at position 1
    if (allow_select_all && pos == 1L) {
      # Special option doesn't have a checkbox, just text
      line <- sprintf("%s   %s", cursor_mark, select_all_text)

      # Apply styling
      if (is_cursor) {
        line <- cli::col_cyan(line)
      } else {
        # Use a slightly different color to distinguish it
        line <- cli::col_silver(line)
      }

      lines <- c(lines, emit_line(line))
    } else {
      # Render normal choice item
      # Map position to choice index (position 2 = index 1, etc.)
      choice_index <- if (allow_select_all) pos - 1L else pos
      is_selected <- choice_index %in% selected_indices

      if (type == "checkbox") {
        checkbox_mark <- if (is_selected) syms$checkbox_on else syms$checkbox_off
        line <- sprintf("%s %s %s", cursor_mark, checkbox_mark, choices[choice_index])
      } else {
        line <- sprintf("%s %s", cursor_mark, choices[choice_index])
      }

      # Apply styling
      if (is_cursor) {
        line <- cli::col_cyan(line)
      }

      lines <- c(lines, emit_line(line))
    }
  }

  # Show indicator if there are items below
  items_below <- effective_length - visible_end
  if (items_below > 0) {
    indicator <- cli::col_silver(sprintf("%s %d more below", syms$arrow_down, items_below))
    lines <- c(lines, emit_line(indicator))
  }

  return(lines)
}

#' Get single keypress from user
#'
#' keypress::keypress() returns special keys as named strings ("up",
#' "down", "enter", "escape", ...) on every platform; regular keys come
#' back as the character itself (space is " ").
#' @keywords internal
#' @importFrom keypress keypress
#' @noRd
get_keypress <- function() {
  key <- keypress::keypress()

  if (key %in% c("up", "k")) {
    return("up")
  }
  if (key %in% c("down", "j")) {
    return("down")
  }
  if (key == " ") {
    return("space")
  }
  if (key == "escape" || tolower(key) == "q") {
    return("esc")
  }

  key
}

#' Move cursor up n lines
#' @keywords internal
#' @noRd
move_cursor_up <- function(n) {
  if (n > 0) {
    cat(sprintf("\033[%dA", n))
  }
}

#' Clear n lines
#' @keywords internal
#' @noRd
clear_lines <- function(n) {
  if (n > 0) {
    for (i in seq_len(n)) {
      move_cursor_up(1)
      cat("\033[2K") # Clear entire line
    }
  }
}
