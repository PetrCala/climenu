#' Interactive CLI Menu
#'
#' Creates an interactive menu in the R console allowing users to select items.
#' Inspired by inquirer.js, Python's pick, and Go's survey libraries.
#'
#' @param choices Character vector of choices to display. When the vector is
#'   named, the names are the labels shown in the menu and the (unnamed) values
#'   are what gets returned, separating display text from stable return
#'   values. Unnamed vectors are displayed and returned as-is.
#' @param prompt Prompt message to display (default: "Select an item:")
#' @param type Menu type: "select" (single) or "checkbox" (multiple) (default: "select")
#' @param selected Pre-selected items (indices or values). Character values
#'   match the returned values first, then the displayed labels.
#' @param return_index Return indices instead of values (default: FALSE)
#' @param max_visible Maximum number of items to display at once (default: 10).
#'   Set to NULL to show all items.
#' @param allow_select_all If `TRUE`, adds a "Select all" / "Deselect all"
#'   option at the top of the menu. Only used when `type = "checkbox"`
#'   (default: FALSE).
#' @param descriptions Optional character vector with one entry per choice,
#'   rendered dim after each label as an aligned second column. Display-only:
#'   descriptions are never echoed or returned, and an empty string renders
#'   nothing for that item (default: NULL).
#' @param echo Print the confirmation line after a completed selection
#'   (default: TRUE). Cancellation notices print regardless.
#'
#' @return Selected item(s) as character vector or indices, or NULL if
#'   cancelled. For named `choices` the unnamed values are returned, not the
#'   displayed labels.
#' @export
#'
#' @examples
#' if (interactive()) {
#'   # Single selection
#'   color <- menu(c("Red", "Green", "Blue"), prompt = "Pick a color:")
#'
#'   # Multiple selection
#'   toppings <- menu(
#'     c("Pepperoni", "Mushrooms", "Olives"),
#'     type = "checkbox",
#'     prompt = "Select toppings:"
#'   )
#' }
menu <- function(choices,
                 prompt = "Select an item:",
                 type = c("select", "checkbox"),
                 selected = NULL,
                 return_index = FALSE,
                 max_visible = 10L,
                 allow_select_all = FALSE,
                 descriptions = NULL,
                 echo = TRUE) {
  type <- match.arg(type)

  if (type == "checkbox") {
    return(checkbox(
      choices = choices,
      prompt = prompt,
      selected = selected,
      return_index = return_index,
      max_visible = max_visible,
      allow_select_all = allow_select_all,
      descriptions = descriptions,
      echo = echo
    ))
  } else {
    return(select(
      choices = choices,
      prompt = prompt,
      selected = selected,
      return_index = return_index,
      max_visible = max_visible,
      descriptions = descriptions,
      echo = echo
    ))
  }
}
