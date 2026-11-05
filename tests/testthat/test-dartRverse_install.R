# Characterization test for dartRverse_install (function-review baseline).
# Snapshots what the function does today, bugs included: it detects change,
# it does not assert correctness. Installers are mocked; nothing is installed.

# Record which installer was called and with what arguments
mock_installers <- function(code) {
  calls <- list()
  with_mocked_bindings(
    with_mocked_bindings(
      code,
      install_github = function(repo, ...) {
        calls[[length(calls) + 1]] <<- list(fun = "install_github",
                                            repo = repo, args = list(...))
        invisible(TRUE)
      },
      .package = "remotes"
    ),
    install.packages = function(pkgs, ...) {
      calls[[length(calls) + 1]] <<- list(fun = "install.packages",
                                          repo = pkgs, args = list(...))
      invisible(NULL)
    },
    dartR_repos = function() c(CRAN = "http://127.0.0.1:9"),
    dartR_prepare_bioc = function(...) invisible(character(0)),
    .package = "dartRverse"
  )
  calls
}

test_that("CRAN install calls install.packages with the package name", {
  calls <- mock_installers(
    res <- dartRverse_install("dartR.sim", rep = "CRAN")
  )
  expect_length(calls, 1)
  expect_equal(calls[[1]]$fun, "install.packages")
  expect_equal(calls[[1]]$repo, "dartR.sim")
  expect_null(res)
})

test_that("Github install calls install_github on the branch", {
  calls <- mock_installers(
    dartRverse_install("dartR.sim", rep = "github", branch = "dev")
  )
  expect_length(calls, 1)
  expect_equal(calls[[1]]$fun, "install_github")
  expect_equal(calls[[1]]$repo, "green-striped-gecko/dartR.sim")
  expect_equal(calls[[1]]$args$ref, "dev")
  expect_true(calls[[1]]$args$dependencies)
  expect_equal(calls[[1]]$args$upgrade, "never")
  expect_equal(calls[[1]]$args$repos, c(CRAN = "http://127.0.0.1:9"))
})

test_that("rep is partially matched", {
  calls <- mock_installers(dartRverse_install("dartR.sim", rep = "G"))
  expect_equal(calls[[1]]$fun, "install_github")
})

# Changed by review change 3: used to print a blank line and return -1
test_that("unknown package errors and installs nothing", {
  calls <- mock_installers(
    expect_error(dartRverse_install("dartR.popgn"),
                 "Unknown dartRverse package: dartR.popgn.*dartR.captive")
  )
  expect_length(calls, 0)
})

# Changed by review change 4: used to return NULL silently
test_that("unrecognised or NULL rep errors and installs nothing", {
  calls <- mock_installers({
    expect_error(dartRverse_install("dartR.sim", rep = "bioconductor"),
                 "rep must be")
    expect_error(dartRverse_install("dartR.sim", rep = NULL), "rep must be")
  })
  expect_length(calls, 0)
})

# dartR.sim needs dartR.popgen, so dartR.popgen goes first whatever the input order
test_that("several packages are installed in dependency order", {
  calls <- mock_installers(
    dartRverse_install(c("dartR.sim", "dartR.popgen"), rep = "Github")
  )
  expect_equal(vapply(calls, `[[`, "", "repo"),
               c("green-striped-gecko/dartR.popgen",
                 "green-striped-gecko/dartR.sim"))
})

# Review change 3 applies to every name before anything is installed
test_that("one bad name in a vector installs nothing", {
  calls <- mock_installers(
    expect_error(dartRverse_install(c("dartR.sim", "dartR.popgn")),
                 "Unknown")
  )
  expect_length(calls, 0)
})

# A loaded package with loaded dependents is replaced without a restart
test_that("reinstalling a loaded package needs no restart", {
  skip_if_not_installed("dartR.base")
  expect_no_warning(
    calls <- mock_installers(
      out <- capture.output(dartRverse_install("dartR.base", rep = "CRAN"))
    )
  )
  expect_false(any(grepl("Restart R", out)))
  expect_true(any(grepl("dartR.base .* is installed", out)))
})

# Review change 6: a failed read shows ? and the table still prints
test_that("listing survives failed GitHub reads", {
  skip_on_cran()
  skip_if_offline("cran.r-project.org")
  out <- with_mocked_bindings(
    capture.output(res <- dartRverse_install()),
    readLines = function(...) stop("cannot open the connection"),
    .package = "base"
  )
  expect_equal(res, 1)
  expect_equal(sum(grepl("dartR\\.", out)), 7)
  expect_true(any(grepl("could not be read from Github", out)))
})

test_that("'all' installs all 7 in dependency order and prints no commands", {
  calls <- mock_installers(
    out <- capture.output(res <- dartRverse_install("all"))
  )
  expect_equal(vapply(calls, `[[`, "", "repo"),
               c("dartR.data", "dartR.base", "dartR.popgen", "dartR.spatial",
                 "dartR.sim", "dartR.captive", "dartR.sexlinked"))
  expect_null(res)
  expect_false(any(grepl("BiocManager|copy the commands", out)))
})

test_that("'all' with a branch installs all 7 from that branch", {
  calls <- mock_installers(
    capture.output(dartRverse_install("ALL", rep = "Github", branch = "dev"))
  )
  expect_length(calls, 7)
  expect_true(all(vapply(calls, function(x) x$args$ref, "") == "dev"))
})

test_that("verbose = FALSE with no package prints nothing", {
  out <- capture.output(res <- dartRverse_install(verbose = FALSE))
  expect_length(out, 0)
  expect_equal(res, 1)
})

test_that("listing prints one line per dartR package", {
  skip_on_cran()
  skip_if_offline("raw.githubusercontent.com")
  out <- capture.output(res <- dartRverse_install())
  expect_equal(res, 1)
  expect_equal(sum(grepl("dartR\\.", out)), 7)
  expect_true(all(grepl("CRAN: .* \\(main\\) .* \\(beta\\) .* \\(dev\\)",
                        out[grepl("dartR\\.", out)])))
})

# Regression tests from the second review
# (function-review/reports/dartRverse/dartRverse_install_review2.md).

# Installers that run the supplied behaviour and record each call
mock_with <- function(code, gh = function(repo, ...) invisible(TRUE),
                      cran = function(pkgs, ...) invisible(NULL)) {
  calls <- character(0)
  with_mocked_bindings(
    with_mocked_bindings(
      code,
      install_github = function(repo, ...) {
        calls <<- c(calls, repo)
        gh(repo, ...)
      },
      .package = "remotes"
    ),
    install.packages = function(pkgs, ...) {
      calls <<- c(calls, pkgs)
      cran(pkgs, ...)
    },
    dartR_repos = function() c(CRAN = "http://127.0.0.1:9"),
    dartR_prepare_bioc = function(...) invisible(character(0)),
    .package = "dartRverse"
  )
  calls
}

# Version table with no network: every remote read fails
offline_table <- function(status) {
  with_mocked_bindings(
    with_mocked_bindings(
      capture.output(res <- dartRverse_install()),
      readLines = function(...) stop("cannot open the connection"),
      .package = "base"
    ),
    available.packages = function(...) stop("offline"),
    dartR_status = function() status,
    .package = "dartRverse"
  )
}

# Change 1
test_that("failed CRAN install errors, skips restart advice, re-attaches", {
  skip_if_not_installed("dartR.sexlinked")
  suppressWarnings(suppressMessages(
    require("dartR.sexlinked", character.only = TRUE, quietly = TRUE)
  ))
  out <- capture.output(
    calls <- mock_with(
      expect_error(dartRverse_install("dartR.sexlinked"),
                   "Installation failed.*dartR.sexlinked"),
      cran = function(pkgs, ...) {
        warning("package 'dartR.sexlinked' is not available for this version of R")
      }
    )
  )
  expect_length(calls, 1)
  expect_false(any(grepl("Restart R", out)))
  expect_true("package:dartR.sexlinked" %in% search())
})

test_that("a failed Github install does not skip the other packages", {
  skip_if_not_installed("dartR.sexlinked")
  sp <- search()
  out <- capture.output(
    calls <- mock_with(
      expect_error(
        dartRverse_install(c("dartR.popgen", "dartR.sexlinked"), rep = "Github"),
        "Installation failed.*dartR.popgen.*HTTP error 404"
      ),
      gh = function(repo, ...) {
        if (grepl("popgen", repo)) stop("HTTP error 404")
        invisible(TRUE)
      }
    )
  )
  expect_length(calls, 2)
  expect_false(any(grepl("dartR.popgen .* is installed", out)))
  expect_true(any(grepl("dartR.sexlinked .* is installed", out)))
  expect_identical(search(), sp)
})

test_that("an unrelated installer warning is not treated as a failure", {
  expect_warning(
    capture.output(
      calls <- mock_with(
        dartRverse_install("dartR.sim"),
        cran = function(pkgs, ...) warning("something harmless")
      )
    ),
    "something harmless"
  )
  expect_length(calls, 1)
})

# Change 2
test_that("no mode uses the attaching helpers", {
  attaching <- function(...) stop("attaching helper called")
  with_mocked_bindings(
    {
      capture.output(mock_with(dartRverse_install("all")))
      capture.output(mock_with(dartRverse_install("dartR.data")))
      capture.output(dartRverse_install(verbose = FALSE))
      offline_table(list(core = "dartR.data", ip = character(0),
                         nip = character(0), failed = character(0)))
    },
    dartR_check = attaching,
    package_version_h = attaching,
    .package = "dartRverse"
  )
  succeed()
})

test_that("version table marks an installed package that fails to load", {
  skip_if_not_installed("dartR.sim")
  out <- offline_table(list(core = "dartR.data", ip = character(0),
                            nip = c("dartR.sim", "dartR.popgen"),
                            failed = "dartR.sim"))
  expect_true(any(grepl("dartR\\.sim.*installed, fails to load", out)))
  expect_false(any(grepl("dartR\\.popgen.*fails to load", out)))
})

test_that("version table copes with an add-on but no core package", {
  skip_if_not_installed("dartR.sim")
  out <- offline_table(list(core = character(0), ip = "dartR.sim",
                            nip = c("dartR.base", "dartR.data"),
                            failed = character(0)))
  expect_equal(sum(grepl("dartR\\.", out)), 3)
})

# Change 3
test_that("branch with CRAN errors and installs nothing", {
  calls <- mock_with({
    expect_error(dartRverse_install("dartR.sim", branch = "dev"),
                 "branch.*rep = 'Github'")
    expect_error(dartRverse_install("dartR.sim", rep = "CRAN", branch = "main"),
                 "branch.*rep = 'Github'")
  })
  expect_length(calls, 0)
})

test_that("branch must be one non-empty string", {
  calls <- mock_with({
    for (b in list(NULL, c("dev", "beta"), "", NA_character_, 1)) {
      expect_error(dartRverse_install("dartR.sim", rep = "Github", branch = b),
                   "branch must be")
    }
  })
  expect_length(calls, 0)
})

test_that("feature branches stay allowed", {
  capture.output(
    calls <- mock_with(
      dartRverse_install("dartR.sim", rep = "Github", branch = "dev_luis")
    )
  )
  expect_length(calls, 1)
})

test_that("empty package errors and duplicates install once", {
  calls <- mock_with(
    expect_error(dartRverse_install(character(0)), "package must name")
  )
  expect_length(calls, 0)
  capture.output(
    calls <- mock_with(dartRverse_install(c("dartR.sim", "dartR.sim")))
  )
  expect_length(calls, 1)
})

# Bioconductor: a small stand-in for available.packages()
fake_db <- function() {
  rows <- list(
    c("dartR.data", "", "CRAN"),
    c("dartR.base", "dartR.data, SNPRelate, snpStats", "CRAN"),
    c("dartR.popgen", "dartR.base, LEA", "CRAN"),
    c("SNPRelate", "gdsfmt", "https://bioconductor.org/packages/3.20/bioc/src/contrib"),
    c("snpStats", "", "https://bioconductor.org/packages/3.20/bioc/src/contrib"),
    c("gdsfmt", "", "https://bioconductor.org/packages/3.20/bioc/src/contrib"),
    c("LEA", "", "https://bioconductor.org/packages/3.20/bioc/src/contrib")
  )
  db <- cbind(Package = vapply(rows, `[`, "", 1), Version = "1.0",
              Depends = NA, Imports = vapply(rows, `[`, "", 2), LinkingTo = NA,
              Suggests = NA, Enhances = NA, Repository = vapply(rows, `[`, "", 3))
  rownames(db) <- db[, "Package"]
  db
}

test_that("needed Bioconductor packages are worked out, including LEA", {
  db <- fake_db()
  expect_length(dartR_bioc_needed("dartR.data", db), 0)
  expect_setequal(dartR_bioc_needed("dartR.base", db),
                  c("SNPRelate", "snpStats", "gdsfmt"))
  expect_true("LEA" %in% dartR_bioc_needed("dartR.popgen", db))
  expect_false("LEA" %in% dartR_bioc_needed("dartR.base", db))
})

# mode: which packages load before and after the fake install
prepare_with <- function(pkgs, loads_before, loads_after) {
  installed <- list(); done <- FALSE
  res <- with_mocked_bindings(
    dartR_prepare_bioc(pkgs, c(CRAN = "http://127.0.0.1:9")),
    available.packages = function(...) fake_db(),
    install.packages = function(pkgs, ...) {
      installed[[length(installed) + 1]] <<- pkgs
      done <<- TRUE
      invisible(NULL)
    },
    dartR_loads = function(p) p %in% if (done) loads_after else loads_before,
    .package = "dartRverse"
  )
  list(res = res, installed = unlist(installed))
}

test_that("nothing is installed when the Bioconductor packages load", {
  ok <- c("SNPRelate", "snpStats", "gdsfmt", "LEA")
  capture.output(r <- prepare_with("dartR.popgen", ok, ok))
  expect_null(r$installed)
})

test_that("a missing or broken Bioconductor package gets installed", {
  ok <- c("SNPRelate", "snpStats", "gdsfmt", "LEA")
  capture.output(r <- prepare_with("dartR.popgen", setdiff(ok, c("LEA", "snpStats")), ok))
  expect_setequal(r$installed, c("LEA", "snpStats"))
})

test_that("a failed Bioconductor install stops before any dartR package changes", {
  sp <- search()
  installs <- character(0)
  capture.output(expect_error(
    with_mocked_bindings(
      dartRverse_install("dartR.popgen"),
      dartR_repos = function() c(CRAN = "http://127.0.0.1:9"),
      available.packages = function(...) fake_db(),
      install.packages = function(pkgs, ...) {
        installs <<- c(installs, pkgs)
        warning("package 'LEA' is not available for Bioconductor version '3.20'")
      },
      dartR_loads = function(p) p != "LEA",
      dartR_unload = function(...) stop("must not unload"),
      .package = "dartRverse"
    ),
    "LEA.*no dartR package was changed.*not available"
  ))
  expect_equal(installs, "LEA")
  expect_identical(search(), sp)
})

test_that("an unreadable package list stops before anything changes", {
  capture.output(expect_error(
    with_mocked_bindings(
      dartR_prepare_bioc("dartR.base", c(CRAN = "http://127.0.0.1:9")),
      available.packages = function(...) stop("cannot open URL"),
      .package = "dartRverse"
    ),
    "internet connection"
  ))
})

test_that("only Bioconductor software and CRAN are used as repositories", {
  skip_if_not_installed("BiocManager")
  repos <- suppressWarnings(dartR_repos())
  expect_setequal(names(repos), c("BioCsoft", "CRAN"))
})

# Unloading and restoring, on the real packages
test_that("search path and namespaces are restored after a success and a failure", {
  skip_if_not_installed("dartR.sim")
  sp <- search()
  ns <- sort(loadedNamespaces())
  capture.output(mock_with(dartRverse_install("dartR.base")))
  expect_identical(search(), sp)
  expect_identical(sort(loadedNamespaces()), ns)
  capture.output(mock_with(
    expect_error(dartRverse_install("dartR.base"), "Installation failed"),
    cran = function(pkgs, ...) stop("no such package")
  ))
  expect_identical(search(), sp)
  expect_identical(sort(loadedNamespaces()), ns)
})

test_that("an interrupted install still restores the session", {
  skip_if_not_installed("dartR.sim")
  sp <- search()
  capture.output(expect_error(
    with_mocked_bindings(
      mock_with(dartRverse_install("dartR.base")),
      dartR_install_one = function(...) stop("interrupted"),
      .package = "dartRverse"
    ),
    "interrupted"
  ))
  expect_identical(search(), sp)
})

test_that("an outside package that imports dartR blocks unloading", {
  skip_if_not_installed("dartR.sexlinked")
  suppressWarnings(suppressMessages(
    require("dartR.sexlinked", character.only = TRUE, quietly = TRUE)
  ))
  sp <- search()
  state <- with_mocked_bindings(
    dartR_unload("dartR.sexlinked"),
    getNamespaceUsers = function(ns) {
      if (ns == "dartR.sexlinked") "otherpkg" else character(0)
    },
    .package = "base"
  )
  expect_equal(state$blocked, "otherpkg")
  expect_equal(state$needs_restart, "dartR.sexlinked")
  expect_length(state$loaded, 0)
  expect_identical(search(), sp)
})

test_that("a blocked package is installed and advises a restart", {
  skip_if_not_installed("dartR.sexlinked")
  out <- capture.output(
    with_mocked_bindings(
      mock_with(dartRverse_install("dartR.sexlinked")),
      dartR_unload = function(pkgs) {
        list(search = search(), loaded = character(0), blocked = "otherpkg",
             needs_restart = pkgs)
      },
      .package = "dartRverse"
    )
  )
  expect_true(any(grepl("Restart R to use the new version of dartR.sexlinked.*otherpkg", out)))
})

test_that("the source-build setting is changed during installs, then restored", {
  old <- options(install.packages.compile.from.source = "interactive")
  on.exit(options(old))
  seen <- NULL
  capture.output(mock_with(
    dartRverse_install("dartR.data"),
    cran = function(pkgs, ...) seen <<- getOption("install.packages.compile.from.source")
  ))
  expect_equal(seen, "never")
  expect_equal(getOption("install.packages.compile.from.source"), "interactive")
})

test_that("unread objects are read, and one that fails does not stop the others", {
  env <- new.env()
  seen <- new.env()
  delayedAssign("a", assign("a", TRUE, envir = seen), assign.env = env)
  delayedAssign("bad", stop("damaged"), assign.env = env)
  delayedAssign(".z", assign(".z", TRUE, envir = seen), assign.env = env)
  expect_no_error(dartR_force_env(env))
  expect_setequal(ls(seen, all.names = TRUE), c("a", ".z"))
})

test_that("objects are read before unloading, also when unloading is blocked", {
  forced <- list()
  unload_with <- function(users) {
    with_mocked_bindings(
      with_mocked_bindings(
        dartR_unload("dartR.fake"),
        loadedNamespaces = function() "dartR.fake",
        getNamespaceUsers = users,
        unloadNamespace = function(...) forced[["unloaded"]] <<- length(forced),
        .package = "base"
      ),
      dartR_install_order = function() "dartR.fake",
      dartR_force_promises = function(pkgs) forced[["pkgs"]] <<- pkgs
    )
  }
  state <- unload_with(function(p) character(0))
  expect_equal(forced$pkgs, "dartR.fake")
  # recorded when unloading: the packages had been read by then
  expect_equal(forced$unloaded, 1L)
  expect_length(state$blocked, 0)

  forced <- list()
  state <- unload_with(function(p) if (p == "dartR.fake") "otherpkg" else character(0))
  expect_equal(state$blocked, "otherpkg")
  expect_equal(forced$pkgs, "dartR.fake")
  expect_null(forced$unloaded)
})

test_that("the settings also apply to the Bioconductor step and are restored", {
  old <- options(timeout = 60, install.packages.compile.from.source = "interactive")
  on.exit(options(old))
  seen <- NULL
  with_mocked_bindings(
    expect_error(dartRverse_install("dartR.data"), "halt"),
    dartR_repos = function() c(CRAN = "http://127.0.0.1:9"),
    dartR_prepare_bioc = function(...) {
      seen <<- options()[c("timeout", "install.packages.compile.from.source")]
      stop("halt")
    }
  )
  expect_equal(seen$timeout, 600)
  expect_equal(seen$install.packages.compile.from.source, "never")
  expect_equal(getOption("timeout"), 60)
  expect_equal(getOption("install.packages.compile.from.source"), "interactive")
})

test_that("a longer timeout set by the user is kept", {
  old <- options(timeout = 7200)
  on.exit(options(old))
  seen <- NULL
  capture.output(mock_with(
    dartRverse_install("dartR.data"),
    cran = function(pkgs, ...) seen <<- getOption("timeout")
  ))
  expect_equal(seen, 7200)
})

test_that("a failed download counts as a failed install", {
  expect_error(
    capture.output(mock_with(
      dartRverse_install("dartR.sim"),
      cran = function(pkgs, ...) warning("download of package 'dartR.sim' failed")
    )),
    "Installation failed for dartR.sim"
  )
})

test_that("a failed download is tried once more", {
  n <- 0
  capture.output(mock_with(
    dartRverse_install("dartR.sim"),
    cran = function(pkgs, ...) {
      n <<- n + 1
      if (n == 1) warning("download of package 'dartR.sim' failed")
    }
  ))
  expect_equal(n, 2)

  # a second failure is reported
  n <- 0
  expect_error(
    capture.output(mock_with(
      dartRverse_install("dartR.sim"),
      cran = function(pkgs, ...) {
        n <<- n + 1
        warning("download of package 'dartR.sim' failed")
      }
    )),
    "Installation failed for dartR.sim"
  )
  expect_equal(n, 2)

  # a failure that is not a download is not tried again
  n <- 0
  expect_error(
    capture.output(mock_with(
      dartRverse_install("dartR.sim"),
      cran = function(pkgs, ...) {
        n <<- n + 1
        warning("installation of package 'dartR.sim' had non-zero exit status")
      }
    )),
    "Installation failed for dartR.sim"
  )
  expect_equal(n, 1)
})

test_that("warnings about unused Bioconductor repositories are dropped", {
  url <- "https://bioconductor.org/packages/3.20/data/annotation/bin/windows/contrib/4.4/PACKAGES"
  for (msg in c(paste0("cannot open URL '", url, "': HTTP status was '404 Not Found'"),
                paste0("unable to access index for repository ", url))) {
    expect_warning(
      capture.output(mock_with(
        dartRverse_install("dartR.sim"),
        cran = function(pkgs, ...) warning(msg)
      )),
      NA
    )
  }
  # the same words about any other address still reach the user
  expect_warning(
    capture.output(mock_with(
      dartRverse_install("dartR.sim"),
      cran = function(pkgs, ...) warning("cannot open URL 'https://example.org/x'")
    )),
    "example.org"
  )
})

test_that("Github installs use the Bioconductor release from BiocManager", {
  old <- Sys.getenv("R_BIOC_VERSION", unset = NA)
  on.exit(if (is.na(old)) Sys.unsetenv("R_BIOC_VERSION") else Sys.setenv(R_BIOC_VERSION = old))
  run <- function() {
    seen <- NULL
    with_mocked_bindings(
      capture.output(mock_with(
        dartRverse_install("dartR.sim", rep = "Github", branch = "dev"),
        gh = function(repo, ...) seen <<- Sys.getenv("R_BIOC_VERSION")
      )),
      version = function() package_version("3.20"),
      .package = "BiocManager"
    )
    seen
  }

  # not set: set during the install, then removed
  Sys.unsetenv("R_BIOC_VERSION")
  expect_equal(run(), "3.20")
  expect_true(is.na(Sys.getenv("R_BIOC_VERSION", unset = NA)))

  # set by the user: left alone
  Sys.setenv(R_BIOC_VERSION = "3.19")
  expect_equal(run(), "3.19")
  expect_equal(Sys.getenv("R_BIOC_VERSION"), "3.19")
})

# Version table
test_that("cells have links only where the console supports them", {
  old <- options(cli.hyperlink = TRUE, cli.hyperlink_run = TRUE)
  on.exit(options(old))
  on <- list(href = TRUE, run = TRUE)
  cell <- dartR_version_cell("dartR.sim", "dev", "1.2.6", on)
  expect_match(cell, "github.com/green-striped-gecko/dartR.sim/tree/dev", fixed = TRUE)
  expect_match(cell, "dartRverse::dartRverse_install('dartR.sim', rep = 'Github', branch = 'dev')", fixed = TRUE)
  cell <- dartR_version_cell("dartR.sim", "CRAN", "1.2.2", on)
  expect_match(cell, "cran.r-project.org/package=dartR.sim", fixed = TRUE)
  expect_match(cell, "dartRverse::dartRverse_install('dartR.sim', rep = 'CRAN')", fixed = TRUE)
  expect_equal(cli::ansi_strip(cell), "1.2.2 [install]")
  expect_equal(dartR_version_cell("dartR.sim", "dev", "1.2.6", list(href = FALSE, run = FALSE)), "1.2.6")
})

test_that("versions that could not be read have no links", {
  on <- list(href = TRUE, run = TRUE)
  expect_equal(dartR_version_cell("dartR.sim", "dev", "?", on), "?")
  expect_true(is.na(dartR_version_cell("dartR.sim", "CRAN", NA_character_, on)))
})

test_that("a plain row keeps the existing layout", {
  v <- c(CRAN = "1.2.2", main = "1.2.2", beta = "?", dev = "1.2.6")
  expect_equal(dartR_table_row("1.2.0", "dartR.sim", v, list(href = FALSE, run = FALSE)),
               "1.2.0 | CRAN: 1.2.2 | Github: 1.2.2 (main) | ? (beta) | 1.2.6 (dev)")
})

test_that("the last row offers all packages or shows the command to type", {
  old <- options(cli.hyperlink = TRUE, cli.hyperlink_run = TRUE)
  on.exit(options(old))
  row <- dartR_all_row(list(href = TRUE, run = TRUE))
  expect_equal(cli::ansi_strip(row), "All packages: [CRAN] [main] [beta] [dev]")
  expect_match(row, "dartRverse::dartRverse_install('all', rep = 'Github', branch = 'dev')", fixed = TRUE)
  expect_match(dartR_all_row(list(href = FALSE, run = FALSE)), "dartRverse_install(\"all\"", fixed = TRUE)
})

# Change 7
test_that("failed version reads leave no connection open", {
  before <- nrow(showConnections(all = TRUE))
  offline_table(list(core = "dartR.data", ip = character(0),
                     nip = character(0), failed = character(0)))
  expect_equal(nrow(showConnections(all = TRUE)), before)
})
