dartRverse_attach_message <- function(to_load, type) {
  if (length(to_load) == 0) {
    return(NULL)
  }

  meta <- switch(
    type,
    core = list(
      label = "Core dartRverse packages",
      symbol = cli::col_green(cli::symbol$tick),
      show_version = TRUE
    ),
    addon = list(
      label = "Installed dartRverse packages",
      symbol = cli::col_green(cli::symbol$tick),
      show_version = TRUE
    ),
    notaddon = list(
      label = "Not [yet] installed dartRverse packages",
      symbol = cli::col_red(cli::symbol$cross),
      show_version = FALSE
    ),
    stop("dartRverse_attach_message: unknown type '", type, "'", call. = FALSE)
  )

  header <- cli::rule(
    left = cli::style_bold(meta$label),
    right = "dartRverse"
  )

  to_load <- sort(to_load)

  if (meta$show_version) {
    versions <- vapply(to_load, package_version_h, character(1))
  } else {
    # notaddon packages are never loaded, so there is no version to show
    versions <- rep("", length(to_load))
  }

  packages <- paste0(
    meta$symbol, " ", cli::col_blue(format(to_load)), " ",
    cli::ansi_align(versions, max(cli::ansi_nchar(versions)))
  )

  if (length(packages) %% 2 == 1) {
    packages <- append(packages, "")
  }
  col1 <- seq_len(length(packages) / 2)
  info <- paste0(packages[col1], "     ", packages[-col1])

  paste0(header, "\n", paste(info, collapse = "\n"))
}

package_version_h <- function(pkg) {
  # requireNamespace() only checks availability; it does not attach pkg to
  # the search path the way require() would.
  if (requireNamespace(pkg, quietly = TRUE)) {
    highlight_version(utils::packageVersion(pkg))
  } else {
    highlight_version("--")
  }
}

highlight_version <- function(x) {
  x <- as.character(x)

  is_dev <- function(x) {
    x <- suppressWarnings(as.numeric(x))
    !is.na(x) & x >= 9000
  }

  pieces <- strsplit(x, ".", fixed = TRUE)
  pieces <- lapply(pieces, function(x) ifelse(is_dev(x), cli::col_red(x), x))
  vapply(pieces, paste, collapse = ".", FUN.VALUE = character(1))
}
