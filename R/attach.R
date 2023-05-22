core <- c("dartR.base")
addons <- c("dartR.data","dartR.spatial", "dartR.sim")
ip <- installed.packages()
installedaddons <- addons[addons %in% ip[,"Package"] ]
notinstalledaddons <- addons[!addons %in% ip[,"Package"] ]
#core <- c(core, installedaddons)


core_unloaded <- function() {
  search <- paste0("package:", core)
  core[!search %in% search()]
}

# Attach the package from the same package library it was
# loaded from before. https://github.com/dartRverse/dartRverse/issues/171
same_library <- function(pkg) {
  loc <- if (pkg %in% loadedNamespaces()) dirname(getNamespaceInfo(pkg, "path"))
  library(pkg, lib.loc = loc, character.only = TRUE, warn.conflicts = FALSE)
}

dartRverse_attach <- function() {
  to_load <- core_unloaded()

  suppressPackageStartupMessages(
    lapply(to_load, same_library)
  )

  invisible(to_load)
}

dartRverse_attach_message <- function(to_load, type) {
  if (length(to_load) == 0) {
    return(NULL)
  }
  if (type=="core") {
  header <- cli::rule(
    left = cli::style_bold("Core dartRverse packages"),
    right = paste0("dartRverse")
  )
  }
  if (type=="addon") {
    header <- cli::rule(
      left = cli::style_bold("Installed dartRverse packages  "),
      right = paste0("dartRverse")
    )
  }
  if (type=="notaddon") {
    header <- cli::rule(
      left = cli::style_bold("Not [yet] installed dartRverse packages"),
      right = paste0("dartRverse")
    )
  }

  to_load <- sort(to_load)
  if (type!="notaddon") {
  versions <- vapply(to_load, package_version_h, character(1)) 

  packages <- paste0(
    cli::col_green(cli::symbol$tick), " ", cli::col_blue(format(to_load)), " ",
    cli::ansi_align(versions, max(cli::ansi_nchar(versions)))
  )
  } else {
    versions=rep("", length(to_load))
    packages <- paste0(
      cli::col_red(cli::symbol$cross), " ", cli::col_blue(format(to_load)), " ",
      cli::ansi_align(versions, max(cli::ansi_nchar(versions)))
    ) 
  }

  if (length(packages) %% 2 == 1) {
    packages <- append(packages, "")
  }
  col1 <- seq_len(length(packages) / 2)
  info <- paste0(packages[col1], "     ", packages[-col1])

  paste0(header, "\n", paste(info, collapse = "\n"))
}

package_version_h <- function(pkg) {
  highlight_version(utils::packageVersion(pkg))
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


