#' Single Selection Menu
#'
#' Interactive menu for selecting a single item from a list.
#' Uses arrow keys (or j/k) to navigate and Enter to select.
#'
#' @param choices Character vector of choices to display. When the vector is
#'   named, the names are the labels shown in the menu and the (unnamed) values
#'   are what gets returned, separating display text from stable return
#'   values. Unnamed vectors are displayed and returned as-is.
#' @param prompt Prompt message to display
#' @param selected Pre-selected item (index or value). A character value
#'   matches the returned values first, then the displayed labels.
#' @param return_index Return index instead of value (default: FALSE)
#' @param max_visible Maximum number of items to display at once (default: 10).
#'   Set to NULL to show all items.
#' @param descriptions Optional character vector with one entry per choice,
#'   rendered dim after each label as an aligned second column. Display-only:
#'   descriptions are never echoed or returned, and an empty string renders
#'   nothing for that item (default: NULL).
#' @param echo Print the confirmation line after a completed selection
#'   (default: TRUE). Cancellation notices print regardless.
#'
#' @return Selected value as character or index, or NULL if cancelled. For
#'   named `choices` the unnamed value is returned, not the displayed label.
#' @export
#'
#' @examples
#' if (interactive()) {
#'   choice <- select(c("Yes", "No", "Maybe"))
#'   index <- select(c("First", "Second", "Third"), return_index = TRUE)
#'
#'   # Labels differ from the returned values
#'   action <- select(c("Run methods" = "run", "Quit" = "quit"))
#'
#'   # With dim descriptions
#'   screen <- select(
#'     c("Studies", "Columns"),
#'     descriptions = c("per-study estimate counts", "role and type per column")
#'   )
#'
#'   # With scrolling for long lists
#'   choice <- select(as.character(1:100), max_visible = 10)
#' }
select <- function(choices,
                   prompt = "Select an item:",
                   selected = NULL,
                   return_index = FALSE,
                   max_visible = 10L,
                   descriptions = NULL,
                   echo = TRUE) {
  # Validate inputs
  validate_choices(choices)
  validate_max_visible(max_visible)
  validate_descriptions(descriptions, choices)
  validate_flag(echo, "echo")

  parts <- resolve_choices(choices)
  labels <- parts$labels
  values <- parts$values

  # Determine initial cursor position
  cursor_pos <- normalize_selected(selected, choices, multiple = FALSE)
  if (is.null(cursor_pos)) cursor_pos <- 1L

  n_choices <- length(choices)

  # Check if running in interactive mode
  if (!interactive()) {
    cli::cli_warn("Not running in interactive mode. Returning the default choice.")
    return(if (return_index) cursor_pos else values[cursor_pos])
  }

  # Fallback for terminals without single-key support (e.g. RStudio/RGui on
  # Windows) or without ANSI escape support (needed to redraw the menu)
  if (!keypress_supported() || !ansi_supported()) {
    return(select_fallback(labels, values, prompt, cursor_pos, return_index, descriptions, echo))
  }

  # Initialize window offset for scrolling
  window_offset <- 1L

  # Adjust initial window to show cursor
  if (!is.null(max_visible) && max_visible < n_choices) {
    # Center cursor in window if possible
    ideal_offset <- cursor_pos - as.integer(max_visible / 2)
    window_offset <- max(1L, min(ideal_offset, n_choices - max_visible + 1L))
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
      selected_indices = NULL,
      type = "select",
      window_offset = window_offset,
      max_visible = max_visible,
      descriptions = descriptions,
      replace_lines = drawn_lines
    )

    drawn_lines <- length(menu_lines)

    # Get user input
    key <- get_keypress()

    # Handle key press (j/k are already mapped to up/down in get_keypress)
    if (key == "up") {
      cursor_pos <- if (cursor_pos > 1) cursor_pos - 1L else n_choices

      # Adjust window if cursor moved outside visible range
      if (!is.null(max_visible) && max_visible < n_choices) {
        if (cursor_pos < window_offset) {
          window_offset <- cursor_pos
        }
        # Handle wrap-around from top to bottom
        if (cursor_pos == n_choices && window_offset != max(1L, n_choices - max_visible + 1L)) {
          window_offset <- max(1L, n_choices - max_visible + 1L)
        }
      }
    } else if (key == "down") {
      cursor_pos <- if (cursor_pos < n_choices) cursor_pos + 1L else 1L

      # Adjust window if cursor moved outside visible range
      if (!is.null(max_visible) && max_visible < n_choices) {
        visible_end <- min(window_offset + max_visible - 1L, n_choices)
        if (cursor_pos > visible_end) {
          window_offset <- cursor_pos - max_visible + 1L
        }
        # Handle wrap-around from bottom to top
        if (cursor_pos == 1L) {
          window_offset <- 1L
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
  if (echo) {
    # Echo the plain label: labels may carry ANSI styling, and inline classes
    # like {.val} would escape those bytes into literal "\033" text
    cli::cli_alert_success("Selected: {.strong {cli::ansi_strip(labels[cursor_pos])}}")
  }

  if (return_index) {
    return(cursor_pos)
  } else {
    return(values[cursor_pos])
  }
}

#' Fallback select for terminals without single-key support
#' @keywords internal
#' @noRd
select_fallback <- function(labels, values, prompt, default_index, return_index,
                            descriptions = NULL, echo = TRUE) {
  notify_fallback_once()
  n_choices <- length(labels)
  width <- cli::console_width()
  rows <- compose_menu_rows(labels, descriptions)

  cat("\n")
  cli::cli_text(prompt)
  cat("\n")
  for (i in seq_len(n_choices)) {
    marker <- if (i == default_index) cli::col_silver(" [default]") else ""
    cat(cli::ansi_strtrim(sprintf("  %d. %s%s", i, rows[i], marker), width), "\n", sep = "")
  }
  cat("\n")

  echo_selection <- function(index) {
    if (!echo) {
      return(invisible())
    }
    cli::cli_alert_success("Selected: {.strong {cli::ansi_strip(labels[index])}}")
  }

  read_choice <- function() {
    raw <- read_line(prompt = sprintf(
      "Enter number 1-%d (Enter for default, q to cancel): ", n_choices
    ))
    trimws(raw)
  }

  for (attempt in 1:2) {
    input <- read_choice()

    if (input == "") {
      echo_selection(default_index)
      return(if (return_index) default_index else values[default_index])
    }
    if (tolower(input) %in% c("q", "quit", "esc")) {
      cli::cli_alert_info("Selection cancelled")
      return(NULL)
    }

    num <- suppressWarnings(as.integer(input))
    if (!is.na(num) && num >= 1L && num <= n_choices) {
      echo_selection(num)
      return(if (return_index) num else values[num])
    }

    if (attempt == 1L) {
      cli::cli_alert_warning("Invalid input. Please enter a number between 1 and {n_choices}.")
    }
  }

  cli::cli_alert_info("Selection cancelled")
  NULL
}
