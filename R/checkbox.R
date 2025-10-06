#' Multiple Selection Menu (Checkbox)
#'
#' Interactive menu for selecting multiple items from a list.
#' Uses arrow keys (or j/k) to navigate, Space to toggle, and Enter to confirm.
#'
#' @param choices Character vector of choices to display
#' @param prompt Prompt message to display
#' @param selected Pre-selected items (indices or values)
#' @param return_index Return indices instead of values (default: FALSE)
#'
#' @return Selected items as character vector or indices, or NULL if cancelled
#' @export
#'
#' @examples
#' \dontrun{
#' toppings <- checkbox(
#'   c("Pepperoni", "Mushrooms", "Olives"),
#'   prompt = "Select toppings:"
#' )
#'
#' # With pre-selection
#' options <- checkbox(
#'   c("Option A", "Option B", "Option C"),
#'   selected = c(1, 3)
#' )
#' }
checkbox <- function(choices,
                     prompt = "Select items (Space to toggle, Enter to confirm):",
                     selected = NULL,
                     return_index = FALSE) {
  # Validate inputs
  validate_choices(choices)

  # Initialize selected items
  selected_indices <- normalize_selected(selected, choices, multiple = TRUE)
  if (is.null(selected_indices)) selected_indices <- integer(0)

  cursor_pos <- 1L
  n_choices <- length(choices)

  # Check if running in interactive mode
  if (!interactive()) {
    cli::cli_warn("Not running in interactive mode. Returning pre-selected or empty.")
    result <- if (length(selected_indices) > 0) selected_indices else integer(0)
    if (return_index) {
      return(result)
    } else {
      return(if (length(result) > 0) choices[result] else character(0))
    }
  }

  # Display prompt
  cat("\n")
  cli::cli_text(prompt)
  cat("\n")

  # Main interaction loop
  repeat {
    # Render menu
    menu_lines <- render_menu(
      choices = choices,
      cursor_pos = cursor_pos,
      selected_indices = selected_indices,
      type = "checkbox"
    )

    n_lines <- length(menu_lines)

    # Get user input
    key <- get_keypress()

    # Clear previous menu
    clear_lines(n_lines)

    # Handle key press
    if (key %in% c("up", "k")) {
      cursor_pos <- if (cursor_pos > 1) cursor_pos - 1L else n_choices
    } else if (key %in% c("down", "j")) {
      cursor_pos <- if (cursor_pos < n_choices) cursor_pos + 1L else 1L
    } else if (key == "space") {
      # Toggle selection
      if (cursor_pos %in% selected_indices) {
        selected_indices <- setdiff(selected_indices, cursor_pos)
      } else {
        selected_indices <- c(selected_indices, cursor_pos)
      }
    } else if (key == "enter") {
      break
    } else if (key == "esc") {
      cat("\n")
      cli::cli_alert_info("Selection cancelled")
      return(NULL)
    }
  }

  cat("\n")
  if (length(selected_indices) > 0) {
    selected_values <- choices[selected_indices]
    cli::cli_alert_success("Selected {length(selected_indices)} item{?s}: {.val {selected_values}}")
  } else {
    cli::cli_alert_info("No items selected")
  }

  if (return_index) {
    return(sort(selected_indices))
  } else {
    return(if (length(selected_indices) > 0) choices[sort(selected_indices)] else character(0))
  }
}
