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
    "Live menus need single-key input and ANSI escapes; this terminal lacks at least one (e.g. RStudio or RGui on Windows). Using numbered-prompt mode."
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
  labels <- names(choices)
  if (!is.null(labels) && (anyNA(labels) || !all(nzchar(labels)))) {
    cli::cli_abort("names(choices) must provide a non-empty label for every choice")
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

#' Split choices into displayed labels and returned values
#'
#' Named vectors separate display text from return values: the names are the
#' labels shown in the menu, the (unnamed) values are what gets returned.
#' Unnamed vectors are displayed and returned as-is.
#' @keywords internal
#' @noRd
resolve_choices <- function(choices) {
  labels <- names(choices)
  if (is.null(labels)) {
    labels <- choices
  }
  list(labels = unname(labels), values = unname(choices))
}

#' Validate the descriptions parameter
#' @keywords internal
#' @noRd
validate_descriptions <- function(descriptions, choices) {
  if (is.null(descriptions)) {
    return(invisible())
  }
  if (!is.character(descriptions) || length(descriptions) != length(choices)) {
    cli::cli_abort("descriptions must be NULL or a character vector with one entry per choice")
  }
  if (anyNA(descriptions)) {
    cli::cli_abort("descriptions must not contain NA values")
  }
  invisible()
}

#' Validate a single-logical flag parameter
#' @keywords internal
#' @noRd
validate_flag <- function(value, name) {
  if (!is.logical(value) || length(value) != 1 || is.na(value)) {
    cli::cli_abort("{name} must be a single logical value")
  }
  invisible()
}

#' Pad a possibly styled string to a display width with plain spaces
#' @keywords internal
#' @noRd
ansi_pad <- function(x, width) {
  pad <- width - cli::ansi_nchar(x)
  paste0(x, strrep(" ", max(pad, 0L)))
}

#' Compose numbered-fallback rows: padded labels with dim descriptions
#'
#' Labels are padded only on rows that carry a description, so the dim column
#' aligns without leaving trailing whitespace on description-less rows.
#' @keywords internal
#' @noRd
compose_menu_rows <- function(labels, descriptions) {
  if (is.null(descriptions)) {
    return(labels)
  }
  label_width <- max(cli::ansi_nchar(labels))
  vapply(seq_along(labels), function(i) {
    if (!nzchar(descriptions[[i]])) {
      return(labels[[i]])
    }
    paste0(ansi_pad(labels[[i]], label_width), "  ", cli::col_grey(descriptions[[i]]))
  }, character(1), USE.NAMES = FALSE)
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
    indices <- which(unname(choices) %in% selected)
    if (length(indices) == 0 && !is.null(names(choices))) {
      indices <- which(names(choices) %in% selected)
    }
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
                        select_all_text = NULL, descriptions = NULL, replace_lines = 0L) {
  type <- match.arg(type)

  syms <- menu_symbols()
  # Truncate to the terminal width so each menu entry occupies exactly one
  # physical row; wrapped rows would break the cursor-up redraw in clear_lines()
  width <- cli::console_width()

  n_choices <- length(choices)
  # Pad labels only on rows that carry a description, so the dim column aligns
  label_width <- if (is.null(descriptions)) 0L else max(cli::ansi_nchar(choices))
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

  # Collect the frame lines; emit_frame() writes them in one go at the end
  lines <- character(0)

  trim_line <- function(line) {
    cli::ansi_strtrim(line, width)
  }

  # Show indicator if there are items above
  items_above <- visible_start - 1L
  if (items_above > 0) {
    indicator <- cli::col_silver(sprintf("%s %d more above", syms$arrow_up, items_above))
    lines <- c(lines, trim_line(indicator))
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

      lines <- c(lines, trim_line(line))
    } else {
      # Render normal choice item
      # Map position to choice index (position 2 = index 1, etc.)
      choice_index <- if (allow_select_all) pos - 1L else pos
      is_selected <- choice_index %in% selected_indices

      label <- choices[choice_index]
      desc <- if (is.null(descriptions)) "" else descriptions[choice_index]
      if (nzchar(desc)) {
        label <- ansi_pad(label, label_width)
      }

      if (type == "checkbox") {
        checkbox_mark <- if (is_selected) syms$checkbox_on else syms$checkbox_off
        line <- sprintf("%s %s %s", cursor_mark, checkbox_mark, label)
      } else {
        line <- sprintf("%s %s", cursor_mark, label)
      }

      # Highlight only the label part under the cursor; the description keeps
      # its dim color, so an SGR reset inside the label cannot bleed into the
      # highlight.
      if (is_cursor) {
        line <- cli::col_cyan(line)
      }
      if (nzchar(desc)) {
        line <- paste0(line, "  ", cli::col_grey(desc))
      }

      lines <- c(lines, trim_line(line))
    }
  }

  # Show indicator if there are items below
  items_below <- effective_length - visible_end
  if (items_below > 0) {
    indicator <- cli::col_silver(sprintf("%s %d more below", syms$arrow_down, items_below))
    lines <- c(lines, trim_line(indicator))
  }

  emit_frame(lines, replace_lines)

  return(lines)
}

#' Get single keypress from user
#'
#' keypress::keypress() returns special keys as named strings ("up",
#' "down", "enter", "escape", ...) on every platform; regular keys come
#' back as the character itself (space is " "). The call stays
#' namespace-qualified (no importFrom): the `::` lookup is live, which is
#' what lets tests mock keypress in its own namespace.
#' @keywords internal
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

#' Emit one menu frame as a single atomic write
#'
#' Erasing and repainting line by line lets the terminal display half-drawn
#' frames, which reads as flicker. Composing the whole frame (cursor
#' repositioning, per-line erase, leftover-row cleanup) into one `cat()` gives
#' the terminal a single write per keystroke. Redraws that replace a previous
#' frame are additionally wrapped in synchronized-output guards
#' (`ESC[?2026h`/`ESC[?2026l`), which capable terminals use to repaint
#' tear-free and other terminals ignore.
#' @keywords internal
#' @noRd
emit_frame <- function(lines, replace_lines = 0L) {
  parts <- character(0)
  if (replace_lines > 0L) {
    parts <- c(parts, "\033[?2026h", sprintf("\033[%dA\r", replace_lines))
  }
  parts <- c(parts, paste0("\033[2K", lines, "\n"))
  leftover <- replace_lines - length(lines)
  if (leftover > 0L) {
    # The new frame is shorter (a scroll indicator disappeared): blank the
    # leftover rows, then move back up so output continues right below the
    # frame
    parts <- c(parts, strrep("\033[2K\n", leftover), sprintf("\033[%dA", leftover))
  }
  if (replace_lines > 0L) {
    parts <- c(parts, "\033[?2026l")
  }
  cat(paste(parts, collapse = ""))
  invisible(lines)
}

#' Clear n lines above the cursor in one write
#' @keywords internal
#' @noRd
clear_lines <- function(n) {
  if (n > 0) {
    cat(strrep("\033[1A\033[2K", n))
  }
}

#' Hide the terminal text cursor while a live menu is on screen
#'
#' The hardware cursor hops across the frame during every redraw, which reads
#' as flicker. Callers must pair this with `show_cursor()` via `on.exit()` so
#' a cancelled menu or an error cannot leave the cursor hidden.
#' @keywords internal
#' @noRd
hide_cursor <- function() {
  cat("\033[?25l")
}

#' Restore the terminal text cursor
#' @keywords internal
#' @noRd
show_cursor <- function() {
  cat("\033[?25h")
}
