#' Multiple Selection Menu (Checkbox)
#'
#' Interactive menu for selecting multiple items from a list.
#' Uses arrow keys (or j/k) to navigate, Space to toggle, and Enter to confirm.
#' Optionally includes a "Select all" / "Deselect all" option at the top when
#' `allow_select_all = TRUE`.
#'
#' @param choices Character vector of choices to display. When the vector is
#'   named, the names are the labels shown in the menu and the (unnamed) values
#'   are what gets returned, separating display text from stable return
#'   values. Unnamed vectors are displayed and returned as-is.
#' @param prompt Prompt message to display
#' @param selected Pre-selected items (indices or values). Character values
#'   match the returned values first, then the displayed labels.
#' @param return_index Return indices instead of values (default: FALSE)
#' @param max_visible Maximum number of items to display at once (default: 10).
#'   Set to NULL to show all items.
#' @param allow_select_all If `TRUE`, adds a "Select all" / "Deselect all" option
#'   at the top of the menu. When selected, toggles all items at once. The option
#'   text dynamically changes based on selection state (default: FALSE).
#' @param descriptions Optional character vector with one entry per choice,
#'   rendered dim after each label as an aligned second column. Display-only:
#'   descriptions are never echoed or returned, and an empty string renders
#'   nothing for that item (default: NULL).
#' @param echo Print the confirmation summary after a completed selection
#'   (default: TRUE). Cancellation notices print regardless.
#'
#' @return Selected items as character vector or indices, or NULL if cancelled.
#'   For named `choices` the unnamed values are returned, not the displayed
#'   labels. The special "Select all" option is never included in the returned
#'   results.
#' @export
#'
#' @examples
#' if (interactive()) {
#'   toppings <- checkbox(
#'     c("Pepperoni", "Mushrooms", "Olives"),
#'     prompt = "Select toppings:"
#'   )
#'
#'   # With pre-selection
#'   options <- checkbox(
#'     c("Option A", "Option B", "Option C"),
#'     selected = c(1, 3)
#'   )
#'
#'   # Labels differ from the returned values
#'   methods <- checkbox(c("Linear tests" = "linear_tests", "BMA" = "bma"))
#'
#'   # With scrolling for long lists
#'   items <- checkbox(as.character(1:100), max_visible = 10)
#'
#'   # With select all feature
#'   methods <- checkbox(
#'     c("method_a", "method_b", "method_c"),
#'     allow_select_all = TRUE,
#'     prompt = "Select methods to run:"
#'   )
#' }
checkbox <- function(choices,
                     prompt = "Select items (Space to toggle, Enter to confirm):",
                     selected = NULL,
                     return_index = FALSE,
                     max_visible = 10L,
                     allow_select_all = FALSE,
                     descriptions = NULL,
                     echo = TRUE) {
  # Validate inputs
  validate_choices(choices)
  validate_max_visible(max_visible)
  validate_descriptions(descriptions, choices)
  validate_flag(allow_select_all, "allow_select_all")
  validate_flag(echo, "echo")

  parts <- resolve_choices(choices)
  labels <- parts$labels
  values <- parts$values

  # Initialize selected items
  selected_indices <- normalize_selected(selected, choices, multiple = TRUE)
  if (is.null(selected_indices)) selected_indices <- integer(0)

  n_choices <- length(choices)

  # When select all is enabled, position 1 is the special option
  # Real choices start at position 2 (which maps to index 1 in choices)
  # Effective menu length includes the special option
  effective_length <- if (allow_select_all) n_choices + 1L else n_choices
  cursor_pos <- 1L

  # Check if running in interactive mode
  if (!interactive()) {
    cli::cli_warn("Not running in interactive mode. Returning pre-selected or empty.")
    result <- if (length(selected_indices) > 0) selected_indices else integer(0)
    if (return_index) {
      return(result)
    } else {
      return(if (length(result) > 0) values[result] else character(0))
    }
  }

  # Fallback for terminals without single-key support (e.g. RStudio/RGui on
  # Windows) or without ANSI escape support (needed to redraw the menu)
  if (!keypress_supported() || !ansi_supported()) {
    return(checkbox_fallback(
      labels, values, prompt, selected_indices, return_index, allow_select_all,
      descriptions, echo
    ))
  }

  # Initialize window offset for scrolling
  window_offset <- 1L

  # Adjust initial window to show cursor
  # When select all is enabled, we need to account for the special option
  if (!is.null(max_visible) && max_visible < effective_length) {
    # Center cursor in window if possible
    ideal_offset <- cursor_pos - as.integer(max_visible / 2)
    window_offset <- max(1L, min(ideal_offset, effective_length - max_visible + 1L))
  }

  # Helper function to compute select all option text
  get_select_all_text <- function() {
    all_selected <- length(selected_indices) == n_choices && n_choices > 0
    if (all_selected) {
      return("Deselect all")
    }
    "Select all"
  }

  # Hide the text cursor for the lifetime of the live menu; restore it on
  # every exit path, including errors and interrupts
  hide_cursor()
  on.exit(show_cursor(), add = TRUE)

  # Display prompt
  cat("\n")
  cli::cli_text(prompt)
  cat("\n")

  # Main interaction loop. Each pass repaints the frame over the previous one
  # in a single write; the frame is only cleared for good on Enter or Esc.
  drawn_lines <- 0L
  repeat {
    # Render menu
    menu_lines <- render_menu(
      choices = labels,
      cursor_pos = cursor_pos,
      selected_indices = selected_indices,
      type = "checkbox",
      window_offset = window_offset,
      max_visible = max_visible,
      allow_select_all = allow_select_all,
      select_all_text = if (allow_select_all) get_select_all_text() else NULL,
      descriptions = descriptions,
      replace_lines = drawn_lines
    )

    drawn_lines <- length(menu_lines)

    # Get user input
    key <- get_keypress()

    # Handle key press (j/k are already mapped to up/down in get_keypress)
    if (key == "up") {
      cursor_pos <- if (cursor_pos > 1) cursor_pos - 1L else effective_length

      # Adjust window if cursor moved outside visible range
      if (!is.null(max_visible) && max_visible < effective_length) {
        if (cursor_pos < window_offset) {
          window_offset <- cursor_pos
        }
        # Handle wrap-around from top to bottom
        if (cursor_pos == effective_length && window_offset != max(1L, effective_length - max_visible + 1L)) {
          window_offset <- max(1L, effective_length - max_visible + 1L)
        }
      }
    } else if (key == "down") {
      cursor_pos <- if (cursor_pos < effective_length) cursor_pos + 1L else 1L

      # Adjust window if cursor moved outside visible range
      if (!is.null(max_visible) && max_visible < effective_length) {
        visible_end <- min(window_offset + max_visible - 1L, effective_length)
        if (cursor_pos > visible_end) {
          window_offset <- cursor_pos - max_visible + 1L
        }
        # Handle wrap-around from bottom to top
        if (cursor_pos == 1L) {
          window_offset <- 1L
        }
      }
    } else if (key == "space") {
      # Handle special select all option
      if (allow_select_all && cursor_pos == 1L) {
        # Toggle all items
        all_selected <- length(selected_indices) == n_choices && n_choices > 0
        if (all_selected) {
          # Deselect all
          selected_indices <- integer(0)
        } else {
          # Select all
          selected_indices <- seq_len(n_choices)
        }
      } else {
        # Normal toggle for real choices
        # Map cursor position to choice index (position 2 = index 1, etc.)
        choice_index <- if (allow_select_all) cursor_pos - 1L else cursor_pos
        if (choice_index %in% selected_indices) {
          selected_indices <- setdiff(selected_indices, choice_index)
        } else {
          selected_indices <- c(selected_indices, choice_index)
        }
      }
    } else if (key == "enter") {
      break
    } else if (key == "esc") {
      clear_lines(drawn_lines)
      cat("\n")
      cli::cli_alert_info("Selection cancelled")
      return(NULL)
    }
  }

  clear_lines(drawn_lines)
  cat("\n")
  echo_checkbox_summary(labels, selected_indices, echo)

  if (return_index) {
    return(sort(selected_indices))
  }
  if (length(selected_indices) > 0) {
    return(values[sort(selected_indices)])
  }
  character(0)
}

#' Echo the confirmation summary of a completed checkbox selection
#'
#' Echoes the plain labels: labels may carry ANSI styling, and inline classes
#' like {.val} would escape those bytes into literal "\033" text.
#' @keywords internal
#' @noRd
echo_checkbox_summary <- function(labels, selected_indices, echo) {
  if (!echo) {
    return(invisible())
  }
  if (length(selected_indices) > 0) {
    cli::cli_alert_success(
      "Selected {length(selected_indices)} item{?s}: {.strong {cli::ansi_strip(labels[sort(selected_indices)])}}"
    )
  } else {
    cli::cli_alert_info("No items selected")
  }
  invisible()
}

#' Fallback checkbox for terminals without single-key support
#' @keywords internal
#' @noRd
checkbox_fallback <- function(labels, values, prompt, selected_indices, return_index,
                              allow_select_all, descriptions = NULL, echo = TRUE) {
  notify_fallback_once()
  n_choices <- length(labels)
  width <- cli::console_width()
  rows <- compose_menu_rows(labels, descriptions)

  cat("\n")
  cli::cli_text(prompt)
  cat("\n")
  for (i in seq_len(n_choices)) {
    mark <- if (i %in% selected_indices) "[x]" else "[ ]"
    cat(cli::ansi_strtrim(sprintf("  %d. %s %s", i, mark, rows[i]), width), "\n", sep = "")
  }
  cat("\n")

  hint <- "Enter numbers to toggle (e.g. 1,3,5)"
  if (allow_select_all) {
    hint <- paste0(hint, ", 'a' to toggle all")
  }
  hint <- paste0(hint, ", Enter to confirm, q to cancel: ")

  raw <- read_line(prompt = hint)
  input <- trimws(raw)

  if (tolower(input) %in% c("q", "quit", "esc")) {
    cli::cli_alert_info("Selection cancelled")
    return(NULL)
  }

  if (nzchar(input)) {
    tokens <- trimws(strsplit(input, ",", fixed = TRUE)[[1]])
    tokens <- tokens[nzchar(tokens)]

    out_of_range <- integer(0)
    invalid <- character(0)

    for (tok in tokens) {
      if (allow_select_all && tolower(tok) == "a") {
        all_selected <- length(selected_indices) == n_choices && n_choices > 0
        selected_indices <- if (all_selected) integer(0) else seq_len(n_choices)
        next
      }

      num <- suppressWarnings(as.integer(tok))
      if (is.na(num)) {
        invalid <- c(invalid, tok)
        next
      }
      if (num < 1L || num > n_choices) {
        out_of_range <- c(out_of_range, num)
        next
      }

      if (num %in% selected_indices) {
        selected_indices <- setdiff(selected_indices, num)
      } else {
        selected_indices <- c(selected_indices, num)
      }
    }

    if (length(invalid) > 0) {
      cli::cli_alert_warning("Ignored non-numeric token{?s}: {.val {invalid}}")
    }
    if (length(out_of_range) > 0) {
      cli::cli_alert_warning("Ignored out-of-range number{?s}: {.val {out_of_range}}")
    }
  }

  echo_checkbox_summary(labels, selected_indices, echo)

  if (return_index) {
    return(sort(selected_indices))
  }
  if (length(selected_indices) > 0) {
    return(values[sort(selected_indices)])
  }
  character(0)
}
