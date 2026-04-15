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

#' Emit a one-time info message explaining the fallback
#' @keywords internal
#' @noRd
notify_fallback_once <- function() {
  if (isTRUE(climenu_env$fallback_notice_shown)) {
    return(invisible())
  }
  cli::cli_alert_info(
    "Your terminal does not support single-key input (e.g. RStudio or RGui on Windows). Using numbered-prompt mode."
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

#' Render menu display
#' @keywords internal
#' @noRd
render_menu <- function(choices, cursor_pos, selected_indices, type = c("select", "checkbox"),
                        window_offset = 1L, max_visible = NULL, allow_select_all = FALSE,
                        select_all_text = NULL) {
  type <- match.arg(type)

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

  # Show indicator if there are items above
  items_above <- visible_start - 1L
  if (items_above > 0) {
    indicator <- cli::col_silver(sprintf("\u2191 %d more above", items_above))
    cat(indicator, "\n", sep = "")
    lines <- c(lines, indicator)
  }

  # Render visible items
  for (pos in visible_start:visible_end) {
    is_cursor <- pos == cursor_pos

    # Handle special select all option at position 1
    if (allow_select_all && pos == 1L) {
      # Render the special "Select all" / "Deselect all" option
      cursor_mark <- if (is_cursor) "\u276f" else " " # <U+276F>
      # Special option doesn't have a checkbox, just text
      line <- sprintf("%s   %s", cursor_mark, select_all_text)

      # Apply styling
      if (is_cursor) {
        line <- cli::col_cyan(line)
      } else {
        # Use a slightly different color to distinguish it
        line <- cli::col_silver(line)
      }

      cat(line, "\n", sep = "")
      lines <- c(lines, line)
    } else {
      # Render normal choice item
      # Map position to choice index (position 2 = index 1, etc.)
      choice_index <- if (allow_select_all) pos - 1L else pos
      is_selected <- choice_index %in% selected_indices

      if (type == "checkbox") {
        checkbox_mark <- if (is_selected) "\u2611" else "\u2610" # <U+2611> or <U+2610>
        cursor_mark <- if (is_cursor) "\u276f" else " " # <U+276F>
        line <- sprintf("%s %s %s", cursor_mark, checkbox_mark, choices[choice_index])
      } else {
        cursor_mark <- if (is_cursor) "\u276f" else " " # <U+276F>
        line <- sprintf("%s %s", cursor_mark, choices[choice_index])
      }

      # Apply styling
      if (is_cursor) {
        line <- cli::col_cyan(line)
      }

      cat(line, "\n", sep = "")
      lines <- c(lines, line)
    }
  }

  # Show indicator if there are items below
  items_below <- effective_length - visible_end
  if (items_below > 0) {
    indicator <- cli::col_silver(sprintf("\u2193 %d more below", items_below))
    cat(indicator, "\n", sep = "")
    lines <- c(lines, indicator)
  }

  return(lines)
}

#' Get single keypress from user
#' @keywords internal
#' @importFrom keypress keypress
#' @noRd
get_keypress <- function() {
  key <- keypress::keypress()

  if (key == "up") {
    return("up")
  }
  if (key == "down") {
    return("down")
  }
  if (key == "left") {
    return("left")
  }
  if (key == "right") {
    return("right")
  }
  if (key == "\r" || key == "\n") {
    return("enter")
  }
  if (key == " ") {
    return("space")
  }
  if (key == "\033" || key == "\x1b") {
    return("esc")
  }
  if (key == "k") {
    return("up")
  }
  if (key == "j") {
    return("down")
  }
  if (tolower(key) == "q") {
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
