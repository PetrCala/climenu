#' Interactive CLI Menu
#'
#' Creates an interactive menu in the R console allowing users to select items.
#' Inspired by inquirer.js, Python's pick, and Go's survey libraries.
#'
#' @param choices Character vector of choices to display
#' @param prompt Prompt message to display (default: "Select an item:")
#' @param type Menu type: "select" (single) or "checkbox" (multiple) (default: "select")
#' @param selected Pre-selected items (indices or values)
#' @param return_index Return indices instead of values (default: FALSE)
#'
#' @return Selected item(s) as character vector or indices, or NULL if cancelled
#' @export
#'
#' @examples
#' \dontrun{
#' # Single selection
#' color <- menu(c("Red", "Green", "Blue"), prompt = "Pick a color:")
#'
#' # Multiple selection
#' toppings <- menu(
#'   c("Pepperoni", "Mushrooms", "Olives"),
#'   type = "checkbox",
#'   prompt = "Select toppings:"
#' )
#' }
menu <- function(choices,
                 prompt = "Select an item:",
                 type = c("select", "checkbox"),
                 selected = NULL,
                 return_index = FALSE) {
  type <- match.arg(type)

  if (type == "checkbox") {
    return(checkbox(
      choices = choices,
      prompt = prompt,
      selected = selected,
      return_index = return_index
    ))
  } else {
    return(select(
      choices = choices,
      prompt = prompt,
      selected = selected,
      return_index = return_index
    ))
  }
}
