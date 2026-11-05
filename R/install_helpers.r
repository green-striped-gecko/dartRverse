# Internal helpers for dartRverse_install(). None of these is exported.

# Dependency order: each package comes after the packages it needs
dartR_install_order <- function() {
  c("dartR.data", "dartR.base", "dartR.popgen", "dartR.spatial", "dartR.sim",
    "dartR.captive", "dartR.sexlinked")
}

# Bioconductor's address depends on the R version, which is why BiocManager is
# needed. Only the software repository is used: the annotation, experiment,
# workflow and book repositories have no Windows binaries, so including them
# prints 404 warnings for packages that dartR does not use.
dartR_repos <- function() {
  repos <- tryCatch(
    suppressWarnings(suppressMessages(BiocManager::repositories())),
    error = function(e) {
      stop(paste0("Could not work out the Bioconductor repository for R ", getRversion(), ": ",
                  conditionMessage(e), "\nNothing was installed."), call. = FALSE)
    })
  repos[names(repos) %in% c("BioCsoft", "CRAN")]
}

# Names of the Bioconductor packages that pkgs need, at any depth.
# db is a matrix from available.packages().
dartR_bioc_needed <- function(pkgs, db) {
  deps <- tools::package_dependencies(intersect(pkgs, rownames(db)), db = db,
                                      which = c("Depends", "Imports", "LinkingTo"),
                                      recursive = TRUE)
  bioc <- rownames(db)[grepl("bioconductor", db[, "Repository"], ignore.case = TRUE)]
  intersect(unique(unlist(deps)), bioc)
}

# TRUE if a package can be used. Being installed is not enough: a package built
# for an older R, for example, is installed but does not load.
dartR_loads <- function(pkg) {
  isTRUE(tryCatch(suppressMessages(suppressWarnings(requireNamespace(pkg, quietly = TRUE))),
                  error = function(e) FALSE))
}

# Runs before anything is unloaded, so a failure here leaves the session as it was.
dartR_prepare_bioc <- function(pkgs, repos) {
  db <- tryCatch(suppressWarnings(available.packages(repos = repos)),
                 error = function(e) NULL)
  if (is.null(db) || nrow(db) == 0) {
    stop(paste0("Could not read the package lists from CRAN and Bioconductor. ",
                "Check your internet connection. Nothing was installed."), call. = FALSE)
  }
  needed <- dartR_bioc_needed(pkgs, db)
  todo <- needed[!vapply(needed, dartR_loads, logical(1))]
  if (length(todo) == 0) return(invisible(character(0)))

  cat(cli::col_green(paste0("  Installing from Bioconductor: ", paste(todo, collapse = ", "), "\n")))
  why <- dartR_install_cran(todo, repos)

  bad <- todo[!vapply(todo, dartR_loads, logical(1))]
  if (length(bad) > 0) {
    stop(paste0("Could not install the Bioconductor package(s) ", paste(bad, collapse = ", "),
                " that dartR needs, so no dartR package was changed.\n",
                if (length(why) > 0) paste0("R reported: ", paste(unique(why), collapse = "; "), "\n"),
                "Bioconductor ", tryCatch(as.character(BiocManager::version()), error = function(e) "?"),
                " is the release for R ", getRversion(), ". ",
                "BiocManager::valid() reports problems with your Bioconductor packages. ",
                "On Linux and macOS, these packages can need system libraries such as zlib."),
         call. = FALSE)
  }
  invisible(todo)
}

# install.packages() reports these failures as warnings and returns normally, so
# they have to be caught by their text. Other warnings, such as a mirror that
# cannot be reached, do not mean that the install failed.
dartR_failure_pattern <- function() {
  "not available|non-zero exit status|cannot remove prior installation|restored|download of package .* failed"
}

# TRUE for a warning about a Bioconductor repository that could not be read. remotes
# reads repositories that dartR does not use and that have no Windows binaries.
# If a package that is needed cannot be downloaded, that is reported separately.
dartR_repo_noise <- function(msg) {
  grepl("bioconductor\\.org", msg, ignore.case = TRUE) &&
    grepl("cannot open URL|unable to access index", msg)
}

# Handles a warning from an install: a failure is passed to add() and not shown
# as a warning, noise is dropped, and anything else reaches the user.
dartR_sort_warning <- function(w, add) {
  msg <- conditionMessage(w)
  if (grepl(dartR_failure_pattern(), msg)) {
    add(msg)
    invokeRestart("muffleWarning")
  }
  if (dartR_repo_noise(msg)) invokeRestart("muffleWarning")
}

# remotes has its own table of Bioconductor releases, which can be out of date
# (it chose 3.18 for R 4.4, where BiocManager says 3.20), but it honours this
# variable. A value the user has set is kept. Returns the value to restore: NA if
# the variable was not set.
dartR_set_bioc_version <- function() {
  old <- Sys.getenv("R_BIOC_VERSION", unset = NA)
  if (is.na(old)) {
    v <- tryCatch(suppressWarnings(suppressMessages(as.character(BiocManager::version()))),
                  error = function(e) NA_character_)
    if (!is.na(v)) Sys.setenv(R_BIOC_VERSION = v)
  }
  old
}

dartR_reset_bioc_version <- function(old) {
  if (is.na(old)) Sys.unsetenv("R_BIOC_VERSION") else Sys.setenv(R_BIOC_VERSION = old)
}

# Runs install.packages() and returns the reasons for any failure, or NULL. Downloads
# from CRAN and Bioconductor fail now and then and work when tried again, so a
# failed download is tried a second time.
dartR_install_cran <- function(pkgs, repos) {
  attempt <- function() {
    why <- NULL
    tryCatch(
      withCallingHandlers(
        install.packages(pkgs, repos = repos),
        warning = function(w) dartR_sort_warning(w, function(msg) why <<- c(why, msg))),
      error = function(e) why <<- c(why, conditionMessage(e)))
    why
  }
  why <- attempt()
  if (any(grepl("download of package .* failed|cannot open URL|Timeout", why))) why <- attempt()
  why
}

# Installs one package. Returns NULL on success or the reason for the failure.
dartR_install_one <- function(pk, rep, branch, repos) {
  if (rep == "CRAN") {
    cat(cli::col_green(paste0("  Installing ", pk, " from CRAN (latest version)\n")))
    why <- dartR_install_cran(pk, repos)
    return(if (is.null(why)) NULL else paste(why, collapse = "; "))
  }
  why <- NULL
  old.bioc <- dartR_set_bioc_version()
  on.exit(dartR_reset_bioc_version(old.bioc), add = TRUE)
  cat(cli::col_green(paste0("  Installing ", pk, " from Github from branch [", branch, "] \n")))
  tryCatch(
    withCallingHandlers({
      # upgrade = "never": a clicked link must not stop at a menu, and upgrading
      # a loaded package with compiled code fails on Windows
      remotes::install_github(paste0("green-striped-gecko/", pk),
                              ref = branch,
                              dependencies = TRUE,
                              upgrade = "never",
                              repos = repos)
    }, warning = function(w) {
      dartR_sort_warning(w, function(msg) why <<- c(why, msg))
    }),
    error = function(e) why <<- c(why, conditionMessage(e))
  )
  if (is.null(why)) NULL else paste(why, collapse = "; ")
}

# Reads everything in an environment that R has not read from disk yet. An error
# leaves that one object unread: the package may already be damaged.
dartR_force_env <- function(env) {
  for (n in ls(env, all.names = TRUE)) tryCatch(get(n, envir = env), error = function(e) NULL)
  invisible(NULL)
}

# R reads a package's functions and datasets only when they are first used, by
# their position in the package's files. Old copies can outlive unloadNamespace(),
# for example as registered S3 methods. If one is read after the files have been
# replaced, R gets the wrong bytes from the new file: "internal error in
# R_decompress1", or a crash that loses the session. Measured with dartR.base going
# from dev to CRAN: 3 crashes in 3 runs without this, none with it.
dartR_force_promises <- function(pkgs) {
  for (p in intersect(pkgs, loadedNamespaces())) {
    ns <- asNamespace(p)
    dartR_force_env(ns)
    if (is.environment(ns$.__NAMESPACE__.$lazydata)) dartR_force_env(ns$.__NAMESPACE__.$lazydata)
  }
  invisible(NULL)
}

# Unloads the packages about to be replaced and every loaded dartR package that
# needs them, leaf packages first. dartR packages have no compiled code, so
# nothing holds their files open once they are unloaded.
# Returns what is needed to put the session back. If a package outside the
# dartRverse imports one of them, nothing is unloaded and blocked names it.
dartR_unload <- function(pkgs) {
  family <- dartR_install_order()
  sp <- search()
  closure <- intersect(pkgs, loadedNamespaces())
  repeat {
    users <- unique(unlist(lapply(closure, getNamespaceUsers)))
    new <- setdiff(users, closure)
    if (length(new) == 0) break
    closure <- c(closure, new)
  }
  blocked <- setdiff(closure, family)
  # also when blocked: a package that stays loaded has its files replaced as well
  dartR_force_promises(intersect(closure, family))
  state <- list(search = sp, loaded = character(0), blocked = blocked,
                needs_restart = intersect(pkgs, loadedNamespaces()))
  if (length(blocked) > 0) return(state)

  state$needs_restart <- character(0)
  state$loaded <- closure
  left <- rev(intersect(family, closure))
  while (length(left) > 0) {
    free <- left[vapply(left, function(p) !any(getNamespaceUsers(p) %in% left), logical(1))]
    if (length(free) == 0) {
      state$blocked <- left
      state$needs_restart <- intersect(pkgs, left)
      return(state)
    }
    for (p in free) {
      ok <- tryCatch({
        ps <- paste0("package:", p)
        if (ps %in% search()) detach(ps, character.only = TRUE)
        unloadNamespace(p)
        TRUE
      }, error = function(e) FALSE)
      if (!ok) {
        state$blocked <- p
        state$needs_restart <- intersect(pkgs, loadedNamespaces())
        return(state)
      }
    }
    left <- setdiff(left, free)
  }
  state
}

# Puts the session back. Each package goes back to its original place on the
# search path, because search order decides which function masks which: dartR.data
# normally sits below dplyr, ggplot2 and adegenet. Returns the packages that
# could not be loaded again.
dartR_restore <- function(state) {
  failed <- character(0)
  was_attached <- state$search[state$search %in% paste0("package:", state$loaded)]
  for (ps in rev(was_attached)) {
    p <- sub("package:", "", ps, fixed = TRUE)
    following <- state$search[seq_along(state$search) > match(ps, state$search)]
    pos <- match(following[following %in% search()][1], search())
    ok <- tryCatch({
      suppressPackageStartupMessages(suppressWarnings(
        library(p, character.only = TRUE, pos = pos, quietly = TRUE)))
      TRUE
    }, error = function(e) FALSE)
    if (!ok) failed <- c(failed, p)
  }
  for (p in setdiff(state$loaded, sub("package:", "", was_attached, fixed = TRUE))) {
    if (!(p %in% loadedNamespaces()) && !dartR_loads(p)) failed <- c(failed, p)
  }
  unique(failed)
}

# Load-only counterpart of dartR_check(): same result structure, except that
# failed holds only names, and nothing is attached to the search path
dartR_status <- function() {
  bc <- vapply(core, dartR_loads, logical(1))
  ba <- vapply(addons, dartR_loads, logical(1))
  notloaded <- c(core[!bc], addons[!ba])
  list(core = core[bc], ip = addons[ba], nip = notloaded,
       failed = notloaded[vapply(notloaded, is_pkg_installed, logical(1))])
}

# Installed version, with the branch if it came from Github
dartR_installed_label <- function(p) {
  label <- highlight_version(utils::packageVersion(p))
  ref <- utils::packageDescription(p, fields = "RemoteRef")
  if (is.character(ref) && !is.na(ref)) label <- paste0(label, " (", ref, ")")
  label
}

# The code run by a link. The dartRverse:: prefix is required by RStudio.
dartR_install_code <- function(p, source) {
  if (source == "CRAN") return(paste0("dartRverse::dartRverse_install('", p, "', rep = 'CRAN')"))
  paste0("dartRverse::dartRverse_install('", p, "', rep = 'Github', branch = '", source, "')")
}

dartR_version_url <- function(p, source) {
  if (source == "CRAN") return(paste0("https://cran.r-project.org/package=", p))
  paste0("https://github.com/green-striped-gecko/", p, "/tree/", source)
}

# TRUE where the console can show this kind of link. RGui and most plain
# terminals cannot run code from a link.
dartR_links <- function() {
  list(href = isTRUE(cli::ansi_has_hyperlink_support()),
       run = isTRUE(cli::ansi_hyperlink_types()$run))
}

# One version in the table. A version that could not be read has no links.
# cli chooses the link format that the console understands.
dartR_version_cell <- function(p, source, version, links) {
  if (is.na(version) || identical(unname(version), "?")) return(as.character(version))
  version <- as.character(version)
  cell <- if (links$href) {
    cli::format_inline(paste0("{.href [", version, "](", dartR_version_url(p, source), ")}"))
  } else version
  if (links$run) {
    cell <- paste0(cell, " ", cli::format_inline(paste0("{.run [[install]](", dartR_install_code(p, source), ")}")))
  }
  cell
}

# One row of the table, for a package and its four available versions
dartR_table_row <- function(state, p, versions, links) {
  paste0(state,
         " | CRAN: ", dartR_version_cell(p, "CRAN", versions[["CRAN"]], links),
         " | Github: ", dartR_version_cell(p, "main", versions[["main"]], links), " (main)",
         " | ", dartR_version_cell(p, "beta", versions[["beta"]], links), " (beta)",
         " | ", dartR_version_cell(p, "dev", versions[["dev"]], links), " (dev)")
}

# The last row of the table: where links run code it offers all packages at once,
# otherwise it shows the command to type
dartR_all_row <- function(links) {
  if (!links$run) {
    return("To install, type for example: dartRverse_install(\"all\", rep = \"Github\", branch = \"dev\")")
  }
  link <- function(text, code) cli::format_inline(paste0("{.run [[", text, "]](", code, ")}"))
  paste("All packages:",
        link("CRAN", "dartRverse::dartRverse_install('all')"),
        link("main", "dartRverse::dartRverse_install('all', rep = 'Github', branch = 'main')"),
        link("beta", "dartRverse::dartRverse_install('all', rep = 'Github', branch = 'beta')"),
        link("dev", "dartRverse::dartRverse_install('all', rep = 'Github', branch = 'dev')"))
}
