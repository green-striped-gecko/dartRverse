#' Checks installed package and Supports installation of CRAN and Github packages of the dartRverse
#'
#' This function installs or updates one or several dartR packages from CRAN or from a Github branch (main, beta or dev), including packages that are loaded at the moment. If run with no parameter the installed packages and the versions available on CRAN and Github are printed.
#'
#' @name dartRverse_install
#' @family dartRverse installation
#' @details
#' \strong{Updating without a restart.} Loaded dartR packages that are affected are unloaded, the new versions are installed, and the packages are loaded again in their original place on the search path. Objects in your workspace are kept. R has to be restarted in two cases, and the function says so: when a package outside the dartRverse imports the dartR package, and on Windows when the update needs a newer version of a loaded third-party package with compiled code. To update dartRverse itself, use install.packages("dartRverse") and restart R.
#'
#' \strong{Bioconductor packages.} Most dartR packages depend on Bioconductor packages, such as SNPRelate, snpStats and LEA, which are not on CRAN. Those that are missing or fail to load are installed first, using the Bioconductor release that BiocManager chooses for your version of R, or the release in the environment variable R_BIOC_VERSION for Github installs if you have set it. If that fails, the function stops before any dartR package is changed. On Linux and macOS these packages can need system libraries, which R cannot install for you.
#'
#' \strong{Failed installs.} If an install fails, the function still tries the other requested packages, restores your session, and then stops with an error naming the packages that failed.
#'
#' \strong{Version table.} Where the console supports it, such as in RStudio, version numbers link to the package on CRAN or Github, and an install link runs the install. Elsewhere the table is plain text. A package that is installed but fails to load is marked. The function does not attach any package to show the table.
#'
#' \strong{Branches.} The 'main' branch on Github is identical with the latest CRAN submission. Important changes and fixes are published under 'beta' and tested there, before they are submitted to CRAN. Hence this might be the best chance to look for fixes. All 'dev' branches are 'risky' meaning they have not been tested.
#'
#' A Github install changes only the named packages. Packages they depend on, such as dartR.base, are not moved to the same branch, so use "all" if you need matching versions. Dependencies that are out of date are not upgraded.
#' @param package Name(s) of the package(s) to install: dartR.base, dartR.data, dartR.sim, dartR.popgen, dartR.spatial, dartR.captive or dartR.sexlinked. Use "all" to install all of them, including those not installed yet, which can take a long time on a new computer. If NULL, the installed packages and the versions available on CRAN and Github are printed [default NULL].
#' @param rep Which repository is used: 'CRAN' or 'Github' (partial matching, any case) [default 'CRAN'].
#' @param branch The Github branch to install from, usually main, beta or dev. It needs rep = 'Github'; supplying it with rep = 'CRAN' is an error [default 'main'].
#' @param verbose If TRUE, the version table is printed when package is NULL; it has no effect otherwise [default TRUE].
#' @return Invisibly: 1 when the version table is requested, NULL otherwise.
#' @author Author(s): Bernd Gruber. Custodian: Bernd Gruber -- Post to \url{https://groups.google.com/d/forum/dartr}
#' @examples
#' # returns without printing the table or installing anything
#' dartRverse_install(verbose = FALSE)
#' \dontrun{
#' # installed packages and available versions (needs internet)
#' dartRverse_install()
#' # install or update all packages from CRAN
#' dartRverse_install("all")
#' # install or update all packages from the dev branch on Github
#' dartRverse_install("all", rep = "Github", branch = "dev")
#' # install or update one package from the beta branch on Github
#' dartRverse_install("dartR.captive", rep = "Github", branch = "beta")
#' }
#' @export
#' @importFrom utils installed.packages install.packages available.packages

dartRverse_install <- function(
                                package = NULL,
                                rep = "CRAN",
                                branch = "main",
                                verbose=TRUE)
{
  #check package
  if (is.null(package))  #just print current versions
  {
    if (verbose>0) {
    # dartR_check() and package_version_h() call require(), which would attach every package to the user's search path
    dc <- dartR_status()
    links <- dartR_links()
    cli::cat_line()
    cli::cat_line("dartRverse packages:")

    # a failed remote read shows "?" instead of stopping the whole table
    failed <- character(0)
    av <- tryCatch(suppressWarnings(available.packages(repos = "https://cran.r-project.org/")),
                   error = function(e) NULL)
    if (is.null(av) || nrow(av) == 0) failed <- c(failed, "CRAN")
    cran_version <- function(p) {
      if ("CRAN" %in% failed) return("?")
      if (p %in% rownames(av)) av[p, "Version"] else NA_character_
    }
    gh_version <- function(p, b) {
      # a failed read does not close the connection by itself
      con <- url(paste0("https://raw.githubusercontent.com/green-striped-gecko/", p, "/", b, "/DESCRIPTION"))
      on.exit(close(con))
      tryCatch({
        myfile <- readLines(con, warn = FALSE)
        gsub(pattern = "Version: ", "", myfile[grep("Version: ", myfile)])[1]
      }, error = function(e) {
        failed <<- c(failed, "Github")
        "?"
      }, warning = function(w) {
        failed <<- c(failed, "Github")
        "?"
      })
    }
    available <- function(p) {
      c(CRAN = cran_version(p), main = gh_version(p, "main"),
        beta = gh_version(p, "beta"), dev = gh_version(p, "dev"))
    }

    loaded <- c(dc$core, dc$ip)
    if (length(loaded) > 0) {
      rows <- vapply(loaded, function(p) {
        dartR_table_row(cli::style_bold(dartR_installed_label(p)), p, available(p), links)
      }, character(1))
      pkg_str <- paste0(
        cli::col_green(cli::symbol$tick), " ", cli::col_blue(format(loaded)), " ",
        cli::ansi_align(rows, max(cli::ansi_nchar(rows))))
      cli::cat_line(pkg_str)
    }

    if (length(dc$nip) > 0) {
      rows <- vapply(dc$nip, function(p) {
        state <- if (p %in% dc$failed) {
          paste0(highlight_version(utils::packageVersion(p)), " installed, fails to load")
        } else {
          "--- "
        }
        dartR_table_row(cli::style_bold(state), p, available(p), links)
      }, character(1))
      pkg_str <- paste0(
        cli::col_red(cli::symbol$cross), " ", cli::col_blue(format(dc$nip)), " ",
        cli::ansi_align(rows, max(cli::ansi_nchar(rows))))
      cli::cat_line(pkg_str)
    }

    cli::cat_line()
    cli::cat_line(dartR_all_row(links))
    cli::cat_line("To update dartRverse itself: install.packages(\"dartRverse\"), then restart R.")

    if (length(failed) > 0) {
      cli::cat_line(cli::col_red(paste0("Versions shown as ? could not be read from ", paste(unique(failed), collapse = " and "), ". Check your internet connection.")))
    }

    }

    return (invisible(1))
  }

  if (identical(tolower(package), "all")) package <- dartR_install_order()

  #make sure all packages exist before installing any
  if (length(package) == 0) {
    stop(paste0("package must name at least one package. Use one of: ", paste(c(core, addons), collapse = ", ")))
  }
  package <- unique(package)
  bad <- package[!package %in% c(core,addons)]
  if (length(bad) > 0) {
    stop(paste0("Unknown dartRverse package: ", paste(bad, collapse = ", "), ". Use one of: ", paste(c(core, addons), collapse = ", ")))
  }
  reps <- c("CRAN", "GITHUB")
  if (is.null(rep) || length(rep) != 1 || is.na(rp <- pmatch(toupper(rep), reps))) {
    stop("rep must be 'CRAN' or 'Github'.")
  }
  rep <- reps[rp]
  # rep defaults to CRAN, where a requested branch would otherwise be ignored and the wrong version installed
  if (rep == "CRAN" && !missing(branch)) {
    stop("branch only applies to Github installs. Use rep = 'Github' to install from a branch.")
  }
  if (!is.character(branch) || length(branch) != 1 || is.na(branch) || !nzchar(branch)) {
    stop("branch must be one branch name, for example 'main', 'beta' or 'dev'.")
  }

  # a package has to be installed after the packages it needs
  package <- intersect(dartR_install_order(), package)
  repos <- dartR_repos()

  # without the first, R can ask whether to build a newer source version, which fails on Windows without Rtools
  # R's default timeout of 60 seconds is too short for the larger packages on a slow connection
  old <- options(install.packages.compile.from.source = "never",
                 timeout = max(600, getOption("timeout")))
  on.exit(options(old), add = TRUE)

  dartR_prepare_bioc(package, repos)

  state <- dartR_unload(package)
  # restoring in on.exit() puts the session back after an error or an interrupt as well
  not.reloaded <- character(0)
  restored <- FALSE
  restore <- function() {
    if (!restored) {
      restored <<- TRUE
      not.reloaded <<- dartR_restore(state)
    }
  }
  on.exit(restore(), add = TRUE)

  install.errors <- character(0)
  for (pk in package) {
    why <- dartR_install_one(pk, rep, branch, repos)
    if (!is.null(why)) install.errors[pk] <- why
  }
  restore()

  for (pk in setdiff(package, names(install.errors))) {
    cat(cli::col_green(paste0("  ", pk, " ", utils::packageVersion(pk), " is installed\n")))
    if (pk %in% state$needs_restart) {
      cat(cli::style_bold(cli::col_red(paste0("  Restart R to use the new version of ", pk,
                                              if (length(state$blocked) > 0) paste0(" (", paste(state$blocked, collapse = ", "), " could not be unloaded)"),
                                              "\n"))))
    }
  }

  # a dev add-on can need functions that are not in an older dartR.base
  if (rep == "GITHUB" && !("dartR.base" %in% package) && is_pkg_installed("dartR.base")) {
    base.version <- utils::packageVersion("dartR.base")
    for (pk in setdiff(package, c(names(install.errors), "dartR.data"))) {
      if (utils::packageVersion(pk) > base.version) {
        cat(cli::col_yellow(paste0("  Note: ", pk, " ", utils::packageVersion(pk), " is newer than dartR.base ", base.version,
                                   ". If it does not work, run: dartRverse_install('dartR.base', rep = 'Github', branch = '", branch, "')\n")))
      }
    }
  }

  problems <- character(0)
  if (length(install.errors) > 0) {
    problems <- paste0("Installation failed for ", paste0(names(install.errors), ": ", install.errors, collapse = "\n"))
  }
  if (length(not.reloaded) > 0) {
    problems <- c(problems, paste0("Could not load again: ", paste(not.reloaded, collapse = ", "), ". Run library(", not.reloaded[1], ") to see the error."))
  }
  if (length(problems) > 0) stop(paste(problems, collapse = "\n"))

  return(invisible(NULL))
}
