#' Update dartRverse packages
#'
#' This will check to see if all dartRverse packages (and optionally, their
#' dependencies) are up-to-date, and will install after an interactive
#' confirmation.
#'
#' @inheritParams dartRverse_deps
#' @export
#' @examples
#' \dontrun{
#' dartRverse_update()
#' }
dartRverse_update <- function(recursive = FALSE, repos = getOption("repos")) {

  deps <- dartRverse_deps(recursive, repos)
  behind <- dplyr::filter(deps, behind)

  if (nrow(behind) == 0) {
    cli::cat_line("All dartRverse packages up-to-date")
    return(invisible())
  }

  cli::cat_line(cli::pluralize(
    "The following {cli::qty(nrow(behind))} dartR.base package{?s} {?is/are} out of date:"
  ))
  cli::cat_line()
  cli::cat_bullet(format(behind$package), " (", behind$local, " -> ", behind$cran, ")")

  cli::cat_line()
  cli::cat_line("To update dartR.base packages, run [in a clean, restarted R session]:")

  pkg_str <- paste0(deparse(behind$package), collapse = "\n")
  cli::cat_line(cli::style_bold("install.packages(", pkg_str, ")"))
  
  cli::cat_line()
  cli::cat_line("Currently installed dartRverse packages:")
  pkg_str <- paste0(deparse(c(core, installedaddons)), collapse = "\n")
  
  cli::cat_line(cli::style_bold(pkg_str))
  
  
  pkg_str <- paste0(deparse(notinstalledaddons),collapse = "\n")
  cli::cat_line()
  cli::cat_line("To install missing dartRverse packages, run [in a clean, restarted R session]:")
  cli::cat_line(cli::style_bold("install.packages(", pkg_str, ")"))
  cli::cat_line()
  cli::cat_line("In case SNPRelate is missing, run [in a clean, restarted R session]:")
  cli::cat_line(cli::style_bold("if (!require('BiocManager')) install.packages('BiocManager')
BiocManager::install(c('SNPRelate', 'qvalue'))"))
  invisible()
}

#' Get a situation report on the dartRverse
#'
#' This function gives a quick overview of the versions of R and RStudio as
#' well as all dartRverse packages. It's primarily designed to help you get
#' a quick idea of what's going on when you're helping someone else debug
#' a problem.
#'
#' @export
dartRverse_sitrep <- function() {
  cli::cat_rule("R")
  cli::cat_bullet("R: ", getRversion())

  deps <- dartRverse_deps()
  package_pad <- format(deps$package)
  packages <- ifelse(
    deps$behind,
    paste0(cli::col_yellow(cli::style_bold(package_pad)), " (", deps$local, " < ", deps$cran, ")"),
    paste0(cli::col_blue(package_pad), " (", highlight_version(deps$local), ")")
  )

  cli::cat_rule("Core packages")
  cli::cat_bullet(packages[deps$package %in% core])
  cli::cat_rule("Non-core packages")
  cli::cat_bullet(packages[!deps$package %in% core])
}

#' List all dartRverse dependencies
#'
#' @param recursive If \code{TRUE}, will also list all dependencies of
#'   dartRverse packages.
#' @param repos The repositories to use to check for updates.
#'   Defaults to \code{getOption("repos")}.
#' @export
dartRverse_deps <- function(recursive = FALSE, repos = getOption("repos")) {
  pkgs <- utils::available.packages(repos = repos)
  #needs to be updated !!!!
  deps <- tools::package_dependencies("dartR", pkgs, recursive = recursive)
  #deps <- tools::package_dependencies("dartRverse", pkgs, recursive = recursive)

  pkg_deps <- unique(sort(unlist(deps)))

  base_pkgs <- c(
    "base", "compiler", "datasets", "graphics", "grDevices", "grid",
    "methods", "parallel", "splines", "stats", "stats4", "tools", "tcltk",
    "utils"
  )
  pkg_deps <- setdiff(pkg_deps, base_pkgs)

  bio_pkgs <- c("SNPRelate", "cli", "rstudioapi")
  pkg_deps <- setdiff(pkg_deps, bio_pkgs)

  cran_version <- lapply(pkgs[pkg_deps, "Version"], package_version)
  local_version <- lapply(pkg_deps, packageVersion)

  behind <- purrr::map2_lgl(cran_version, local_version, `>`)

  tibble::tibble(
    package = pkg_deps,
    cran = cran_version %>% purrr::map_chr(as.character),
    local = local_version %>% purrr::map_chr(as.character),
    behind = behind
  )
}

packageVersion <- function(pkg) {
  if (rlang::is_installed(pkg)) {
    utils::packageVersion(pkg)
  } else {
    0
  }
}
