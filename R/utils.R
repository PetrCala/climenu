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
                        window_offset = 1L, max_visible = NULL) {
  type <- match.arg(type)

  n_choices <- length(choices)

  # Determine visible range
  if (is.null(max_visible) || max_visible >= n_choices) {
    # Show all items (backward compatible)
    visible_start <- 1L
    visible_end <- n_choices
  } else {
    visible_start <- window_offset
    visible_end <- min(window_offset + max_visible - 1L, n_choices)
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
  for (i in visible_start:visible_end) {
    is_cursor <- i == cursor_pos
    is_selected <- i %in% selected_indices

    if (type == "checkbox") {
      checkbox_mark <- if (is_selected) "\u2611" else "\u2610"  # ☑ or ☐
      cursor_mark <- if (is_cursor) "\u276f" else " "  # ❯
      line <- sprintf("%s %s %s", cursor_mark, checkbox_mark, choices[i])
    } else {
      cursor_mark <- if (is_cursor) "\u276f" else " "  # ❯
      line <- sprintf("%s %s", cursor_mark, choices[i])
    }

    # Apply styling
    if (is_cursor) {
      line <- cli::col_cyan(line)
    }

    cat(line, "\n", sep = "")
    lines <- c(lines, line)
  }

  # Show indicator if there are items below
  items_below <- n_choices - visible_end
  if (items_below > 0) {
    indicator <- cli::col_silver(sprintf("\u2193 %d more below", items_below))
    cat(indicator, "\n", sep = "")
    lines <- c(lines, indicator)
  }

  return(lines)
}

#' Get single keypress from user
#' @keywords internal
#' @noRd
get_keypress <- function() {
  # Check for keypress package (best option for single-key capture)
  if (requireNamespace("keypress", quietly = TRUE)) {
    key <- keypress::keypress()

    # Map special keys
    if (key == "up") return("up")
    if (key == "down") return("down")
    if (key == "left") return("left")
    if (key == "right") return("right")
    if (key == "\r" || key == "\n") return("enter")
    if (key == " ") return("space")
    if (key == "\033" || key == "\x1b") return("esc")
    if (key == "k") return("up")
    if (key == "j") return("down")
    if (tolower(key) == "q") return("esc")

    return(key)
  }

  # Fallback: Use readline (requires Enter key)
  # Show hint only once per session
  env <- get("climenu_env", envir = asNamespace("climenu"))
  if (!exists(".climenu_keypress_hint_shown", envir = env)) {
    cli::cli_alert_info("For better keyboard support, install: {.code install.packages('keypress')}")
    assign(".climenu_keypress_hint_shown", TRUE, envir = env)
  }

  key <- readline(prompt = "Choice (\u2191/\u2193/j/k/number/Enter): ")

  # Map text input to commands
  key <- tolower(trimws(key))

  if (key == "" || key == "enter") return("enter")
  if (key == " " || key == "space") return("space")
  if (key == "up" || key == "u" || key == "k") return("up")
  if (key == "down" || key == "d" || key == "j") return("down")
  if (key == "esc" || key == "q" || key == "quit") return("esc")

  # Try to parse as number (for quick selection by index)
  num <- suppressWarnings(as.integer(key))
  if (!is.na(num)) {
    return(list(type = "number", value = num))
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
      cat("\033[2K")  # Clear entire line
    }
  }
}
